'use strict';
// Issue 918. Node 22, built-in modules only. Source files are always read-only.
const fs = require('fs');
const path = require('path');
const http = require('http');
const { randomUUID } = require('crypto');
const { isIP } = require('net');
const tailscale = require('./tailscale');

const REPO = 'https://github.com/rcbailey12/voidsworn';
const SEATS = [
  ['main', 'Codex main', 'board'], ['b', 'Codex lane B', 'board_b'],
  ['c', 'Codex lane C', 'board_c'], ['d', 'Codex lane D', 'board_d'],
  ['deepseek', 'DeepSeek', 'work217']
];
const STALE_SECONDS = 1800;
const OFFLINE_SECONDS = 180;
const GITHUB_SECONDS = 300;
const iso = n => Number.isFinite(n) && n > 0 ? new Date(n).toISOString() : null;
const time = s => { const n = Date.parse(s); return Number.isFinite(n) ? n : 0; };
const maxTime = (...ns) => Math.max(0, ...ns.filter(Number.isFinite));
const lanePattern = /^(codex_chain_[a-z0-9_]+|codex_lane_[bcd][a-z0-9_]*|ds_[a-z0-9_]+)\.txt$/i;
const laneId = name => /^ds_/i.test(name) ? 'deepseek' : (name.match(/^codex_lane_([bcd])/i) || [0, 'main'])[1].toLowerCase();

class Reader {
  constructor() { this.cache = new Map(); this.errors = new Set(); this.readBytes = 0; }
  stat(p) {
    try { const s = fs.lstatSync(p); return s.isFile() ? s : null; }
    catch (e) { if (e.code !== 'ENOENT') this.errors.add(p); return null; }
  }
  dirs(p) {
    try { return fs.readdirSync(p, { withFileTypes: true }).filter(d => !d.isSymbolicLink()); }
    catch (e) { if (e.code !== 'ENOENT') this.errors.add(p); return []; }
  }
  read(p, limit = 65536, tail = false) {
    const s = this.stat(p);
    if (!s) return { text: '', mtime: 0, exists: false };
    const key = `${p}:${limit}:${tail}`;
    const cached = this.cache.get(key);
    if (cached && cached.size === s.size && cached.mtime === s.mtimeMs) return cached;
    try {
      const count = Math.min(limit, s.size), buf = Buffer.alloc(count);
      const fd = fs.openSync(p, 'r');
      try { fs.readSync(fd, buf, 0, count, tail ? s.size - count : 0); }
      finally { fs.closeSync(fd); }
      this.readBytes += count;
      const v = { text: buf.toString('utf8').replace(/^\uFEFF/, ''), mtime: s.mtimeMs, size: s.size, exists: true };
      this.cache.set(key, v);
      return v;
    } catch (_) { this.errors.add(p); return { text: '', mtime: s.mtimeMs, exists: true, unreadable: true }; }
  }
}

// Never execute a .bat. Recognize only the runner/list forms used by the Board.
function parseIssues(bat) {
  const found = [];
  for (const line of bat.split(/\r?\n/)) {
    if (/^\s*(rem\b|::)/i.test(line)) continue;
    const loop = /for\s+%%\w\s+in\s*\(([\d\s]+)\)\s+do\s+call\s+:one\s+%%\w/i.exec(line);
    if (loop) found.push(...loop[1].trim().split(/\s+/).map(Number));
    const direct = /\bcall\s+[^\r\n]*?(?:codex_issue|work_issue|RUN_RETRY)\.bat"?\s+([1-9]\d*)/i.exec(line);
    if (direct) found.push(Number(direct[1]));
  }
  return found.filter(n => Number.isSafeInteger(n) && n > 0);
}

function eventTime(line, anchor) {
  const clock = /\b(\d{1,2}):(\d{2}):(\d{2})(?:\.(\d+))?/.exec(line);
  if (!clock) return anchor;
  const date = /\b(\d{1,2})\/(\d{1,2})\/(\d{4})\b/.exec(line);
  const d = new Date(anchor);
  if (date) d.setFullYear(+date[3], +date[1] - 1, +date[2]);
  const before = d.getTime();
  d.setHours(+clock[1], +clock[2], +clock[3], Number((clock[4] || '').padEnd(3, '0').slice(0, 3)));
  if (!date && d.getTime() < before - 12 * 3600000) d.setDate(d.getDate() + 1);
  return d.getTime();
}

function readChain(root, name, reader) {
  const src = reader.read(path.join(root, name));
  const bat = reader.read(path.join(root, name.replace(/\.txt$/i, '.bat')));
  const issues = parseIssues(bat.text);
  let current = null, lastIssue = null, currentAt = 0, endedAt = 0, cursor = 0, anchor = src.mtime;
  let done = false, started = false, predecessor = null, stopped = false;
  for (const line of src.text.split(/\r?\n/)) {
    const wait = /^waiting for ([a-z0-9_]+\.txt)\b/i.exec(line);
    if (wait && lanePattern.test(wait[1])) predecessor = wait[1].toLowerCase();
    if (/^(?:start|setup)\s/i.test(line)) { anchor = eventTime(line, anchor); started = /^start\s/i.test(line); }
    const e = /^\s*(\d+)\s+(start|end)\s/i.exec(line);
    if (e) {
      anchor = eventTime(line, anchor);
      const index = issues.indexOf(+e[1], cursor);
      if (e[2].toLowerCase() === 'start') {
        current = +e[1]; lastIssue = current; currentAt = anchor; started = true;
        if (index >= 0) cursor = index;
      } else { current = null; endedAt = anchor; if (index >= 0) cursor = index + 1; }
    }
    if (/^all done\b/i.test(line)) { done = true; current = null; endedAt = eventTime(line,anchor); }
    if (/paused by the Board|\bstopped\b/i.test(line)) { stopped = true; done = true; current = null; }
  }
  return { name, id: laneId(name), issues, current, lastIssue, currentAt, endedAt, cursor, done, started,
    stopped, waiting: !!predecessor && !started && !done, predecessor, mtime: src.mtime,
    unreadable: src.unreadable || bat.unreadable, missingBat: !bat.exists };
}

// Text is inspected locally, never copied to the payload. Only known status reasons escape.
function safeReason(raw) {
  const s = String(raw || '');
  const reasons = [
    [/usage limit/i, 'Usage limit hit; left on the board to retry.'],
    [/chain stopped: predecessor status.json is missing/i, 'Chain stopped: predecessor status is missing.'],
    [/chain stopped: predecessor run (?:changed|id does not match)/i, 'Chain stopped: predecessor run changed.'],
    [/chain stopped: predecessor ended/i, 'Chain stopped: predecessor did not make a checked push.'],
    [/chain stopped: predecessor did not finish/i, 'Chain stopped: predecessor exceeded the wait limit.'],
    [/chain waiting/i, 'Waiting for the predecessor to make a checked push.'],
    [/\bSTALLED\b|stall limit/i, 'Runner stopped: no progress before the stall limit.'],
    [/\bCEILING\b|hard ceiling/i, 'Runner stopped: hard run ceiling reached.'],
    [/free.space|free space|below.*floor/i, 'Runner refused: not enough free disk space.'],
    [/preflight failed/i, 'Runner preflight failed.'],
    [/already carries running|claim stayed locked/i, 'Runner refused: another run owns the claim.'],
    [/cannot validate or claim|claim did not land/i, 'Runner refused: GitHub claim could not be verified.'],
    [/current instruction refused/i, 'Runner refused: current issue instructions are invalid.'],
    [/clone failed|clone.*(?:failed|exhausted)/i, 'Runner failed: checkout could not be cloned.'],
    [/push failed|push stopped|DIFF MISMATCH/i, 'Runner stopped: push was not confirmed.'],
    [/non-partial push confirmed and runner checks passed/i, 'Checked push confirmed; runner checks passed.'],
    [/dry\/test push or checks did not pass/i, 'Push or checks unverified; chain stays stopped.'],
    [/no changes pushed|agent made no changes/i, 'No changes pushed; chain stays stopped.'],
    [/agent left a merge unfinished/i, 'Partial run: an unfinished merge remains.'],
    [/agent exit (\d+)/i, m => `Partial run: agent exit ${m[1]}.`],
    [/runner exit (\d+)/i, m => `Runner exit ${m[1]}.`]
  ];
  for (const [re, value] of reasons) { const m = re.exec(s); if (m) return typeof value === 'function' ? value(m) : value; }
  return s.trim() ? 'Runner reason is unrecognized; inspect it locally.' : null;
}

function cleanTitle(s, issue) {
  if (typeof s !== 'string' || !s.trim()) return `Issue #${issue} (title unavailable)`;
  // Titles are job metadata; discard anything resembling a path, email, token or log dump.
  if (s.length > 240 || /[\r\n]|[a-z]:[\\/]|\\\\|\/Users\/|\/home\/|@|(?:gh[pousr]_|github_pat_|sk-)[a-z0-9_]+|(?:token|password|secret|api[_ -]?key)\s*[:=]/i.test(s)) return `Issue #${issue} (title withheld)`;
  return s.trim().replace(/[\u0000-\u001f\u007f]/g, '').replace(/\u2014/g, '-');
}

function titleFromLog(text, issue) {
  // A Codex task header, a workhorse task header, or the JSON-escaped equivalent.
  const normalized = text.replace(/\\"/g, '"').replace(/\\n/g, '\n');
  const re = new RegExp(`(?:Codex|Workhorse) job: issue #${issue}, "([^"\\r\\n]+)"`, 'i');
  return (re.exec(normalized) || [])[1];
}

function jobInfo(folder, issue, seat, reader) {
  const state = reader.read(path.join(folder, 'status.json'));
  let status = null;
  try { status = JSON.parse(state.text); } catch (_) { /* Unknown, never a success. */ }
  const result = reader.read(path.join(folder, 'result.txt'), 8192, true);
  const logStat = reader.stat(path.join(folder, 'log.txt'));
  const log = reader.read(path.join(folder, 'log.txt'), 16384);
  const started = time(status && status.started);
  const finished = time(status && status.finished);
  const checks = ['checks_node.txt', 'checks_parity.txt'].map(name => [name, reader.stat(path.join(folder, name))]);
  const activity = maxTime(state.mtime, logStat && logStat.mtimeMs, result.mtime, ...checks.map(([,s]) => s && s.mtimeMs));
  const logTail = reader.read(path.join(folder, 'log.txt'), 8192, true);
  const lastOutput = [logTail,result].filter(x=>x.exists).sort((a,b)=>b.mtime-a.mtime)[0];
  const ended = /clone failed|push stopped|all done/i.test(lastOutput?.text.trim().split(/\r?\n/).at(-1) || '');
  const title = cleanTitle((status && status.title) || titleFromLog(log.text, issue), issue);
  const branch = seat === 'deepseek' ? `work/issue-${issue}-${/deepseekpro/i.test(folder) ? 'deepseekpro' : 'deepseek'}` : `codex/issue-${issue}`;
  const job = { issue, title, branch, url: `${REPO}/issues/${issue}`,
    prUrl: `${REPO}/pulls?q=${encodeURIComponent('is:pr head:' + branch)}` };
  return { issue, job, started, finished, activity, logAt: logStat && logStat.mtimeMs, ended, updated: activity,
    state, status, result, files: [state.exists && 'status.json', result.exists && 'result.txt', logStat && 'log.txt', ...checks.filter(([,s]) => s).map(([name]) => name)].filter(Boolean) };
}

function readJobs(root, seat, reader) {
  const jobs = [];
  const base = path.join(root, seat[2]);
  for (const d of reader.dirs(base)) {
    if (!d.isDirectory()) continue;
    const m = (seat[0] === 'deepseek' ? /^issue-(\d+)-(deepseek|deepseekpro)$/i : /^issue-(\d+)$/i).exec(d.name);
    if (!m) continue;
    if (seat[0] !== 'deepseek') jobs.push(jobInfo(path.join(base, d.name), +m[1], seat[0], reader));
    else {
      // Read latest.txt only as a pointer to an existing direct child run. Never follow arbitrary paths.
      const p = path.join(base, d.name), latest = reader.read(path.join(p, 'latest.txt'), 4096);
      const run = latest.text.trim().split(/[\\/]/).pop();
      const runs = reader.dirs(p).filter(x => x.isDirectory() && /^\d{8}_\d{6}$/.test(x.name)).map(x => x.name).sort();
      if (runs.includes(run)) jobs.push(jobInfo(path.join(p, run, 'out'), +m[1], seat[0], reader));
      else {
        const candidates = [...(runs.length ? [jobInfo(path.join(p, runs.at(-1), 'out'), +m[1], seat[0], reader)] : []), jobInfo(path.join(p, 'out'), +m[1], seat[0], reader)];
        const selected = candidates.filter(j => j.updated).sort((a,b) => b.updated-a.updated)[0];
        if (selected) jobs.push(selected);
      }
    }
  }
  return jobs;
}

function classify(info) {
  if (!info) return { state: 'unknown', reason: 'No runner status is available.' };
  const s = info.status && info.status.status;
  const raw = (info.status && info.status.reason) || info.result.text;
  const reason = safeReason(raw);
  if (s === 'running') {
    if (/usage limit hit|chain stopped:/i.test(info.result.text)) return { state: 'blocked', reason: safeReason(info.result.text) };
    if (/chain waiting for/i.test(info.result.text) && !/chain released:|agent running|preflight passed/i.test(info.result.text)) return { state: 'waiting', reason: 'Waiting for the predecessor to make a checked push.' };
    return { state: 'running', reason: null };
  }
  if (s === 'checked_push') return { state: 'finished', reason: 'Checked push confirmed; runner checks passed.' };
  if (['partial', 'unverified', 'no_changes', 'blocked'].includes(s)) return { state: 'blocked', reason: reason || 'Runner did not produce a checked push; chain stays stopped.' };
  if (s === 'failed') return { state: /chain stopped|refused|usage limit|free.space/i.test(raw) ? 'blocked' : 'failed', reason: reason || 'Runner reported a failure.' };
  // Older runners have result.txt but no status.json. Text may prove a failure, never a checked success.
  if (/usage limit|chain stopped|preflight failed|push failed|clone failed|refuse step failed/i.test(info.result.text)) return { state: /usage limit|chain stopped/i.test(info.result.text) ? 'blocked' : 'failed', reason: reason || 'Runner reported a failure.' };
  return { state: 'unknown', reason: info.state.exists ? 'Runner status is unreadable or unrecognized.' : 'Runner status is missing; text cannot prove a checked finish.' };
}

function chainOrder(chains) {
  const ordered = [], pending = [...chains].sort((a, b) => a.mtime - b.mtime || a.name.localeCompare(b.name));
  while (pending.length) {
    const index = pending.findIndex(c => !pending.some(p => p.name.toLowerCase() === c.predecessor));
    ordered.push(pending.splice(index < 0 ? 0 : index, 1)[0]);
  }
  return ordered;
}

function emptyGithub() { return { lastReadAt:null, lastAttemptAt:null, ok:false, coverageComplete:false, issues:[], pulls:[], needsRyan:[], crew:{} }; }
const issueNumber = n => Number.isSafeInteger(n) && n > 0;
const branchPattern = /^(?:codex|work|opus|muse)\/issue-\d+(?:-[a-z0-9_-]+)?$/i;
function pictureLink(raw) {
  if (typeof raw !== 'string') return null;
  const link = (/^\[[^\]]*\]\(([^)]+)\)$/.exec(raw.trim()) || [null,raw.trim()])[1];
  try {
    const u = new URL(link);
    return u.protocol === 'https:' && !u.username && !u.password && !u.search && !u.hash &&
      (u.hostname === 'github.com' && u.pathname.startsWith('/rcbailey12/voidsworn/') || u.hostname === 'raw.githubusercontent.com' && u.pathname.startsWith('/rcbailey12/voidsworn/')) ? u.href : null;
  } catch (_) { return null; }
}
function askRyan(body, number) {
  let fence = false;
  for (const line of String(body || '').split(/\r?\n/)) {
    if (/^\s*(```|~~~)/.test(line)) { fence = !fence; continue; }
    const match = !fence && /^Ask Ryan: (.+?) \| Picture: (.+)$/.exec(line);
    if (match) return { question:cleanTitle(match[1],number), picture:pictureLink(match[2]) };
  }
  return null;
}
function githubData(issues, pulls, comments, previous, now) {
  if (![issues,pulls,comments].every(Array.isArray)) throw Error('Invalid GitHub list');
  const data = emptyGithub();
  data.lastReadAt = iso(now); data.lastAttemptAt = iso(now); data.ok = true;
  // One bounded page per source. Do not turn an incomplete first page into a claim of zero questions.
  data.coverageComplete = issues.length < 100 || !!previous.coverageComplete && time(issues.at(-1)?.updated_at) <= time(previous.lastReadAt);
  data.issues = [...previous.issues]; data.pulls = [...previous.pulls]; data.crew = {...previous.crew};
  const put = (list, item, key) => { const index=list.findIndex(x=>x[key]===item[key]); if(index<0)list.push(item);else list[index]=item; };
  const record = (seat,at,action,number) => {
    if (time(at) && (!data.crew[seat] || time(at)>time(data.crew[seat].at))) data.crew[seat]={at:iso(time(at)),action,number,url:`${REPO}/${action==='Technical review recorded'?'issues':'pull'}/${number}`};
  };
  for (const issue of issues) {
    if (!issueNumber(issue.number) || issue.pull_request) continue;
    const ask = issue.state === 'open' && Array.isArray(issue.labels) && issue.labels.some(l=>(typeof l==='string'?l:l?.name)==='ryan') ? askRyan(issue.body,issue.number) : null;
    put(data.issues,{number:issue.number,title:cleanTitle(issue.title,issue.number),updatedAt:iso(time(issue.updated_at)),ask},'number');
  }
  for (const pr of pulls) {
    if (!issueNumber(pr.number) || pr.base?.repo?.full_name !== 'rcbailey12/voidsworn') continue;
    const own = pr.head?.repo?.full_name === 'rcbailey12/voidsworn', branch = own && pr.head?.ref;
    const state = pr.merged_at ? 'merged' : pr.state === 'open' ? 'open' : 'closed';
    if (branchPattern.test(branch)) put(data.pulls,{number:pr.number,branch,state,updatedAt:iso(time(pr.updated_at)),url:`${REPO}/pull/${pr.number}`},'number');
    if (own && /^opus\//.test(branch)) record('claude',pr.updated_at,'Branch update recorded',pr.number);
    if (own && /^muse\//.test(branch)) record('muse',pr.updated_at,pr.merged_at?'Merged PR recorded':'Branch update recorded',pr.number);
    // A merge commit is visible in this read. Direct Board commits are not exposed by these three endpoints.
    if (pr.merged_at && /^[a-f0-9]{40}$/i.test(pr.merge_commit_sha || '')) record('claude',pr.merged_at,'Board merge commit recorded',pr.number);
  }
  for (const comment of comments) {
    const m = /^https:\/\/api\.github\.com\/repos\/rcbailey12\/voidsworn\/issues\/(\d+)$/.exec(comment.issue_url || '');
    if (m && String(comment.body || '').startsWith('Artoo (technical review):')) record('artoo',comment.updated_at,'Technical review recorded',+m[1]);
  }
  data.issues.sort((a,b)=>time(b.updatedAt)-time(a.updatedAt)); data.pulls.sort((a,b)=>time(b.updatedAt)-time(a.updatedAt));
  // Retain marked questions even when they fall outside the latest update window.
  data.issues = data.issues.filter((x,i)=>i<500 || x.ask); data.pulls = data.pulls.slice(0,500);
  data.needsRyan = data.issues.filter(x=>x.ask).map(x=>({issue:x.number,title:x.title,url:`${REPO}/issues/${x.number}`,updatedAt:x.updatedAt,...x.ask}));
  return data;
}
function enrichJob(job, github) {
  const issue=github.issues.find(x=>x.number===job.issue);
  if (issue && /\(title (?:unavailable|withheld)\)$/.test(job.title)) job.title=issue.title;
  const pr=github.pulls.filter(x=>x.branch===job.branch).sort((a,b)=>time(b.updatedAt)-time(a.updatedAt))[0];
  if(pr){job.prState=pr.state;job.prNumber=pr.number;job.prUrl=pr.url;}
}
class GithubReader {
  constructor(fetcher = fetch, initial = emptyGithub()) { this.fetcher=fetcher; this.data=initial; this.busy=false; }
  async update(now = Date.now()) {
    if(this.busy || this.data.lastAttemptAt && now-time(this.data.lastAttemptAt)<GITHUB_SECONDS*1000) return this.data;
    this.busy=true;
    const previous=this.data, since=previous.lastReadAt || iso(now-7*86400000);
    const base='https://api.github.com/repos/rcbailey12/voidsworn/';
    const urls=[base+'issues?state=all&sort=updated&direction=desc&per_page=100',base+'pulls?state=all&sort=updated&direction=desc&per_page=100',base+'issues/comments?sort=updated&direction=desc&per_page=100&since='+encodeURIComponent(since)];
    try {
      const results=await Promise.allSettled(urls.map(async url=>{
        const res=await this.fetcher(url,{method:'GET',redirect:'error',headers:{Accept:'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28','User-Agent':'voidsworn-mission-control'},signal:AbortSignal.timeout(8000)});
        if(!res.ok)throw Error('GitHub unavailable');
        let body='',bytes=0;
        const decoder=new TextDecoder();
        for await(const chunk of res.body){bytes+=chunk.length;if(bytes>4*1024*1024){throw Error('GitHub response too large');}body+=decoder.decode(chunk,{stream:true});}
        return JSON.parse(body+decoder.decode());
      }));
      if(results.some(x=>x.status!=='fulfilled'))throw Error('GitHub read incomplete');
      this.data=githubData(...results.map(x=>x.value),previous,now);
    }catch(_){this.data={...previous,ok:false,lastAttemptAt:iso(now)};}
    finally{this.busy=false;}
    return this.data;
  }
}

function snapshot(root, now = Date.now(), reader = new Reader(), github = emptyGithub()) {
  reader.errors.clear();
  const chains = reader.dirs(root).filter(d => d.isFile() && lanePattern.test(d.name)).map(d => readChain(root, d.name, reader));
  const lanes = SEATS.map(seat => {
    const own = chains.filter(c => c.id === seat[0]);
    const jobs = readJobs(root, seat, reader).sort((a, b) => (b.started || b.updated) - (a.started || a.updated));
    // Select the newest started chain before checking completion. A completed newer
    // chain still replaces older abandoned chains; a waiting chain does not.
    const latestEvent = own.filter(c => c.started && c.lastIssue).sort((a,b) => b.currentAt-a.currentAt)[0];
    let chain = latestEvent && !latestEvent.done ? latestEvent : null;
    const chainIssue = chain && (chain.current || chain.lastIssue);
    let info = jobs[0];
    if (chain && !chain.current && info && info.issue !== chainIssue && (info.started || info.updated) > chain.currentAt + 2000) chain = null;
    // A live chain names the running or just-ended job. Old rerun outputs cannot supply its status.
    if (chain) {
      info = jobs.find(j => j.issue === chainIssue);
      if (info && info.started && info.started < chain.currentAt - 2000) info = null;
    }
    let unverifiedEvent = null;
    if (!chain && latestEvent && (!info || latestEvent.currentAt > (info.started || info.updated) + 2000)) {
      unverifiedEvent = latestEvent;
      info = null;
    }
    const waiters = chainOrder(own.filter(c => c.waiting));
    const verdict = classify(info);
    const ended = seat[0] === 'deepseek' && latestEvent && latestEvent.done && !latestEvent.stopped && info && info.issue === latestEvent.lastIssue && info.ended && verdict.state !== 'finished';
    if (ended) { verdict.state = 'idle'; verdict.reason = 'Run ended without a confirmed push.'; }
    if (latestEvent && latestEvent.stopped && info && info.issue === latestEvent.lastIssue && verdict.state === 'running') {
      verdict.state = 'idle'; verdict.reason = 'The Board stopped this chain; its running record is last known.';
    }
    let current = info && info.job, started = info && info.started || chain && chain.currentAt || ended && latestEvent.currentAt, activity = info && info.activity;
    const sources = [], next = [];
    if (chain) sources.push(chain.name);
    if (unverifiedEvent) {
      sources.push(unverifiedEvent.name);
      current = { issue: unverifiedEvent.lastIssue, title: cleanTitle(null, unverifiedEvent.lastIssue), url: `${REPO}/issues/${unverifiedEvent.lastIssue}` };
      started = unverifiedEvent.currentAt;
      verdict.reason = 'The latest chain ran this issue, but no matching runner status confirms its result.';
    }
    if (chain && !info) {
      current = { issue: chainIssue, title: cleanTitle(null, chainIssue), url: `${REPO}/issues/${chainIssue}`,
        prUrl: `${REPO}/pulls?q=${encodeURIComponent('is:pr head:codex/issue-' + chainIssue)}` };
      started = chain.currentAt;
    }
    // End advances cursor to the next job; start leaves it at the current job.
    if (chain && !chain.missingBat) next.push(...chain.issues.slice(chain.cursor + (chain.current ? 1 : 0)));
    for (const c of waiters) { sources.push(c.name); next.push(...c.issues); }
    if (!current && waiters.length) { verdict.state = 'waiting'; verdict.reason = 'Queued behind another chain; no current job is confirmed.'; }
    if (!current && !waiters.length && own.length) sources.push([...own].sort((a, b) => b.mtime - a.mtime)[0].name);
    const stale = !!(current && (['running', 'waiting'].includes(verdict.state) || chain && verdict.state === 'unknown') && (!activity ? now - (started || now) >= STALE_SECONDS * 1000 : now - activity >= STALE_SECONDS * 1000));
    const warnings = [];
    if (own.some(c => c.unreadable)) warnings.push('A lane source could not be read.');
    if (chain && chain.missingBat || waiters.some(c => c.missingBat)) warnings.push('A chain script is missing; its next jobs are unknown.');
    if (!current && !waiters.length && !own.length) warnings.push('No lane feed found.');
    const leftovers = chain && chain.current ? jobs.filter(j => j.issue !== chainIssue && !chain.issues.includes(j.issue) && j.status && j.status.status === 'running' && now-j.activity >= STALE_SECONDS*1000).map(j => ({job:j.job,lastActivityAt:iso(j.activity)})) : [];
    if (chain && chain.current) for (const j of jobs.filter(j => j.issue !== chainIssue && !chain.issues.includes(j.issue) && j.status && j.status.status === 'running')) warnings.push(`Stray job folder: issue #${j.issue}.`);
    return { id: seat[0], label: seat[1], state: verdict.state, runnerState: info && typeof info.status?.status === 'string' && ['running','checked_push','partial','unverified','no_changes','blocked','failed'].includes(info.status.status) ? info.status.status : 'unknown', stale, endedWithoutPush: !!ended, leftovers, current: current || null,
      startedAt: iso(started), finishedAt: iso(info && info.finished || latestEvent && latestEvent.done && latestEvent.lastIssue === current?.issue && latestEvent.endedAt), logAt: iso(info && info.logAt), lastActivityAt: iso(activity), reason: verdict.reason,
      next: [...new Set(next)].filter(n => n !== (current && current.issue)).map(n => {
        const known = jobs.find(j => j.issue === n);
        return known ? known.job : { issue: n, title: cleanTitle(null, n), url: `${REPO}/issues/${n}` };
      }), source: { lanes: [...new Set(sources)], runner: info ? `${seat[1]} runner, issue #${info.issue}` : null,
        files: info ? info.files : [], updatedAt: iso(maxTime(info && info.updated, ...own.filter(c => sources.includes(c.name)).map(c => c.mtime))), refreshedAt: iso(now) }, warnings };
  });
  for (const lane of lanes) for (const job of [lane.current,...lane.next,...lane.leftovers.map(x=>x.job)].filter(Boolean)) {
    job.branch ||= lane.id === 'deepseek' ? `work/issue-${job.issue}-deepseek` : `codex/issue-${job.issue}`;
    enrichJob(job,github);
  }
  return { schemaVersion: 1, generatedAt: iso(now), staleAfterSeconds: STALE_SECONDS, offlineAfterSeconds: OFFLINE_SECONDS,
    github, lanes, warnings: reader.errors.size ? ['Some PC sources could not be read; affected rows may be unknown.'] : [] };
}

function checkOutputParents(out) {
  for (let p = path.resolve(out); ; p = path.dirname(p)) {
    try { if (fs.lstatSync(p).isSymbolicLink()) throw new Error('Output must not use a junction or symbolic link.'); }
    catch (e) { if (e.code !== 'ENOENT') throw e; }
    if (path.dirname(p) === p) break;
  }
}

function writeSnapshot(out, data) {
  checkOutputParents(out);
  fs.mkdirSync(out, { recursive: true });
  const target = path.join(out, 'status.json'), temp = path.join(out, `status.${randomUUID()}.pending`);
  fs.writeFileSync(temp, JSON.stringify(data, null, 2) + '\n', {flag:'wx'});
  fs.renameSync(temp, target);
}

function options(args) {
  const opts = { root: path.join(process.env.USERPROFILE || process.env.HOME || '.', 'Downloads', 'voidsworn_test'), port: 8918, once: false };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--once') opts.once = true;
    else if (['--root', '--out', '--port'].includes(args[i]) && args[i + 1]) opts[args[i].slice(2)] = args[++i];
    else throw new Error('Use --root <PC folder>, --out <local output folder>, --port <port>, or --once.');
  }
  opts.root = path.resolve(opts.root);
  opts.out = path.resolve(opts.out || path.join(opts.root, 'mission_local'));
  const relative = path.relative(opts.root, opts.out);
  if (!relative || (!relative.startsWith('..') && /^(?:board(?:_[bcd])?|work217|queue[^\\/]*|build[^\\/]*)(?:[\\/]|$)/i.test(relative))) throw new Error('Output must be separate from all lane, job, build and queue folders.');
  checkOutputParents(opts.out);
  opts.port = Number(opts.port);
  if (!Number.isInteger(opts.port) || opts.port < 1 || opts.port > 65535) throw new Error('Port must be 1 to 65535.');
  return opts;
}

function allowedHost(req, port, tailnetHost) {
  if (req.headers['tailscale-funnel-request'] !== undefined) return false;
  if ([`127.0.0.1:${port}`, `localhost:${port}`].includes(req.headers.host)) return true;
  const host = req.headers.host;
  const forwarded = req.headers['x-forwarded-for'];
  const tailnetIP = typeof forwarded === 'string' && (
    (isIP(forwarded) === 4 && /^100\.(?:6[4-9]|[7-9]\d|1[01]\d|12[0-7])\./.test(forwarded)) ||
    (isIP(forwarded) === 6 && /^fd7a:115c:a1e0:/i.test(forwarded)));
  // Serve connects over loopback and replaces these proxy headers. Local processes
  // remain trusted; these headers are not authentication against software on this PC.
  return Boolean(tailnetHost && [tailnetHost, `${tailnetHost}:443`].includes(host) &&
    req.socket.remoteAddress === '127.0.0.1' &&
    req.headers['x-forwarded-host'] === host && req.headers['x-forwarded-proto'] === 'https' && tailnetIP);
}

function serve(opts, discover = tailscale.discover, githubReader = new GithubReader()) {
  const reader = new Reader();
  const publish = () => writeSnapshot(opts.out, snapshot(opts.root, Date.now(), reader, githubReader.data));
  publish();
  const update = async () => { await githubReader.update(); try { publish(); } catch (_) { console.error('Snapshot failed; last good snapshot kept.'); } };
  if (opts.once) return update();
  void update();
  const tailnetHost = discover().host;
  const page = path.resolve(__dirname, '../../../docs/mission/index.html');
  const server = http.createServer((req, res) => {
    // Fixed routes only, never a directory server or an upload endpoint.
    const route = req.url.split('?')[0];
    if (!allowedHost(req, opts.port, tailnetHost)) { res.writeHead(403).end('Local host required'); return; }
    if (req.method !== 'GET' && req.method !== 'HEAD') { res.writeHead(405).end(); return; }
    const assets = {'/artoo.svg':'image/svg+xml','/ChakraPetch-SemiBold.ttf':'font/ttf','/Barlow-Regular.ttf':'font/ttf','/AzeretMono-VF.ttf':'font/ttf'};
    const file = route === '/' || route === '/index.html' ? page : route === '/status.json' ? path.join(opts.out, 'status.json') : Object.hasOwn(assets,route) ? path.join(path.dirname(page),route.slice(1)) : null;
    if (!file) { res.writeHead(404).end(); return; }
    try {
      const body = fs.readFileSync(file);
      res.writeHead(200, { 'Content-Type': assets[route] || (route === '/status.json' ? 'application/json; charset=utf-8' : 'text/html; charset=utf-8'),
        'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', 'Referrer-Policy': 'no-referrer' });
      res.end(req.method === 'HEAD' ? undefined : body);
    } catch (_) { res.writeHead(503).end('Local snapshot unavailable'); }
  });
  const timer = setInterval(() => { try { publish(); void update(); } catch (_) { console.error('Snapshot failed; last good snapshot kept.'); } }, 60000);
  const stop = () => { clearInterval(timer); server.close(); };
  server.on('close', () => clearInterval(timer));
  server.on('error', () => { clearInterval(timer); console.error('Local server could not start. Check whether its port is in use.'); process.exitCode = 1; });
  process.once('SIGINT', stop); process.once('SIGTERM', stop);
  server.listen(opts.port, '127.0.0.1', () => console.log(`Mission control: http://127.0.0.1:${opts.port}\nLocal only. Close this window or press Ctrl+C to stop. Refresh: once a minute.`));
  return server;
}

module.exports = { Reader, GithubReader, emptyGithub, githubData, cleanTitle, SEATS, parseIssues, eventTime, safeReason, snapshot, classify, writeSnapshot, options, serve, allowedHost };
if (require.main === module) {
  try { serve(options(process.argv.slice(2))); }
  catch (_) { console.error('Mission control could not read or write its local folders. Check arguments and folder access.'); process.exitCode = 1; }
}
