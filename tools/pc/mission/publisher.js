'use strict';
// Issue 918. Node 22, built-in modules only. Source files are always read-only.
const fs = require('fs');
const path = require('path');
const http = require('http');
const { randomUUID, createHash } = require('crypto');
const { spawnSync } = require('child_process');
const { Worker, isMainThread, workerData, parentPort } = require('worker_threads');
const queue = require('./queue');
const { Budget, sourceRecord, backoff, SOURCE_INTERVAL_MS } = require('./budget');
const { isIP } = require('net');
const tailscale = require('./tailscale');

const REPO = 'https://github.com/rcbailey12/voidsworn';
const SEATS = [
  ['main', 'Codex main', 'board'], ['b', 'Codex lane B', 'board_b'],
  ['c', 'Codex lane C', 'board_c'], ['d', 'Codex lane D', 'board_d'],
  ['deepseek', 'DeepSeek', 'work217'], ['openai', 'OpenAI', 'work217']
];
const WORKHORSE_ARMS = {deepseek:['deepseek','deepseekpro'],openai:['openai']};
const branchFor = (issue, seat, arm = seat) => WORKHORSE_ARMS[seat] ? `work/issue-${issue}-${arm}` : `codex/issue-${issue}`;
const STALE_SECONDS = 1800;
const OFFLINE_SECONDS = 180;
const CLAIM_SECONDS = 600;
const iso = n => Number.isFinite(n) && n > 0 ? new Date(n).toISOString() : null;
const time = s => { const n = Date.parse(s); return Number.isFinite(n) ? n : 0; };
const maxTime = (...ns) => Math.max(0, ...ns.filter(Number.isFinite));
const lanePattern = queue.filePattern;
// Public diagnostics are built from known operations and error codes. Raw error
// messages can include filesystem paths, request headers and response excerpts.
const PC_ERRORS = {EACCES:'access denied',EPERM:'access denied',EBUSY:'file busy',ENOENT:'file or folder missing',
  ENOTDIR:'expected a folder',EIO:'I/O error',EMFILE:'too many open files',ENFILE:'too many open files',ENOSPC:'disk full'};
const NETWORK_ERRORS = {ENOTFOUND:'DNS lookup failed',EAI_AGAIN:'DNS lookup could not complete',ECONNRESET:'connection reset',
  ECONNREFUSED:'connection refused',ETIMEDOUT:'connection timed out',UND_ERR_CONNECT_TIMEOUT:'connection timed out',
  UND_ERR_SOCKET:'connection closed',CERT_HAS_EXPIRED:'TLS certificate expired',UNABLE_TO_VERIFY_LEAF_SIGNATURE:'TLS certificate could not be verified'};
const knownError = (codes, code, fallback) => Object.hasOwn(codes,code) ? codes[code] : fallback;
class Reader {
  constructor() { this.cache = new Map(); this.imageHashes = new Map(); this.errors = new Set(); this.readBytes = 0; this.lastSuccessfulReadAt = null; }
  error(operation, error) { this.errors.add(operation+': '+knownError(PC_ERRORS,error?.code,'read failed')); }
  imageHash(file, stat) {
    const key = `${stat.size}:${stat.mtimeMs}:${stat.ctimeMs}`;
    const previous = this.imageHashes.get(file);
    if (previous?.key === key) return previous.hash;
    try {
      const hash = createHash('sha256').update(fs.readFileSync(file)).digest('hex');
      this.imageHashes.set(file, {key, hash});
      return hash;
    } catch (error) { this.error('Picture read',error); return null; }
  }
  stat(p, source = 'File metadata', required = false) {
    try {
      const s = fs.lstatSync(p);
      if (s.isFile()) return s;
      if (required) this.errors.add(source+': expected a regular file');
    } catch (e) { if (required || e.code !== 'ENOENT') this.error(source,e); }
    return null;
  }
  dirs(p, required = false, source = 'Folder listing') {
    try { return fs.readdirSync(p, { withFileTypes: true }).filter(d => !d.isSymbolicLink()); }
    catch (e) { if (required || e.code !== 'ENOENT') this.error(source,e); return []; }
  }
  directory(p, source) {
    try {
      if (fs.lstatSync(p).isDirectory()) return true;
      this.errors.add(source+': expected a regular directory');
    } catch (e) { this.error(source,e); }
    return false;
  }
  read(p, limit = 65536, tail = false, source, required = false) {
    const s = this.stat(p,source,required);
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
    } catch (error) { this.error(source || 'File read',error); return { text: '', mtime: s.mtimeMs, exists: true, unreadable: true }; }
  }
}

const {parseIssues, eventTime} = queue;
function readChain(root, name, reader, files = new Map(reader.dirs(root).filter(d=>d.isFile()).map(d=>[d.name.toLowerCase(),d.name]))) {
  const src = reader.read(path.join(root, name));
  const batName = files.get(name.toLowerCase().replace(/\.txt$/, '.bat'));
  const bat = batName ? reader.read(path.join(root, batName)) : {text:'',mtime:0,exists:false};
  return queue.parseChain({name, text:src.text, bat:bat.text, mtime:src.mtime, batMtime:bat.mtime,
    missingBat:!bat.exists, unreadable:src.unreadable || bat.unreadable});
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

function hasLocalUser(text) {
  const name = process.env.USERNAME;
  if (!name) return false;
  const escaped = name.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
  return new RegExp('(^|[^a-z0-9_])'+escaped+'($|[^a-z0-9_])','i').test(text);
}
function publicText(s) {
  // Discard anything resembling a path, email, token or log dump.
  if (typeof s !== 'string' || s.length > 240 || hasLocalUser(s) || /[\r\n]|[a-z]:[\\/]|\\\\|\/Users\/|\/home\/|@|(?:gh[pousr]_|github_pat_|sk-)[a-z0-9_]+|(?:token|password|secret|api[_ -]?key)\s*[:=]/i.test(s)) return null;
  return s.replace(/[\u0000-\u001f\u007f]/g, '').replace(/\u2014/g, '-').trim() || null;
}
function cleanTitle(s, issue) {
  return publicText(s) || `Issue #${issue} (title ${typeof s === 'string' && s.trim() ? 'withheld' : 'unavailable'})`;
}

function titleFromLog(text, issue) {
  // A Codex task header, a workhorse task header, or the JSON-escaped equivalent.
  const normalized = text.replace(/\\"/g, '"').replace(/\\n/g, '\n');
  const re = new RegExp(`(?:Codex|Workhorse) job: issue #${issue}, "([^"\\r\\n]+)"`, 'i');
  return (re.exec(normalized) || [])[1];
}

const runId = value => typeof value === 'string' && /^[a-f0-9]{32}$/i.test(value) ? value.toLowerCase() : null;
const sha = value => typeof value === 'string' && /^[a-f0-9]{40,64}$/i.test(value) ? value.toLowerCase() : null;
function resultVerdict(text) {
  if (/chain stopped:|usage limit|push stopped|no changes pushed|agent made no changes/i.test(text)) return 'blocked';
  if (/clone failed|preflight failed|push failed|refuse step failed|runner exit [1-9]\d*|agent exit [1-9]\d*/i.test(text)) return 'failed';
  if (/chain waiting for/i.test(text) && !/chain released:|agent running|preflight passed/i.test(text)) return 'waiting';
  if (/all done/i.test(text)) return 'ended';
  return null;
}
function jobInfo(folder, issue, seat, reader, byLocation = false, arm = seat, source) {
  const fileSource = name => source ? source+'/'+name : undefined;
  const read = (name, limit, tail) => reader.read(path.join(folder,name),limit,tail,fileSource(name));
  const state = read('status.json');
  let status = null;
  if (state.exists && !state.unreadable) {
    try { status = JSON.parse(state.text); } catch (_) { /* Invalid status is reported below. */ }
    if (!status || typeof status!=='object' || Array.isArray(status)) {
      status = null;
      reader.errors.add(source ? fileSource('status.json')+': invalid runner status' : 'Runner status file is invalid');
    }
  }
  const head = read('result.txt',65536);
  const tail = read('result.txt',16384,true);
  const result = {...tail, text:head.text + '\n' + tail.text};
  const claims = [...result.text.matchAll(/job claimed: issue #(\d+) by ([a-z]+), run ([a-f0-9]{32})(?![a-f0-9])/gi)];
  const tags = [...new Set(claims.map(m => m[3].toLowerCase()))];
  const run = runId(status?.run), tagged = tags.length === 1 ? tags[0] : null;
  const branch = branchFor(issue,seat,arm);
  const foreignRunner = WORKHORSE_ARMS[seat] && (
    seat === 'openai' && (!run || status.branch !== branch) ||
    status && (status.branch && status.branch !== branch ||
      status.github?.seat && status.github.seat !== arm || status.github?.issue && Number(status.github.issue) !== issue) ||
    claims.some(m => +m[1] !== issue || m[2].toLowerCase() !== arm));
  const resultStartLine = result.text.split(/\r?\n/).find(l=>/^started\s/i.test(l));
  const resultStarted = resultStartLine ? eventTime(resultStartLine,result.mtime) : 0;
  const mismatch = !!(run && tagged && run !== tagged);
  const previous = mismatch && (resultStarted && resultStarted < time(status?.started)-2000 || result.mtime < time(status?.started));
  const resultMatches = !foreignRunner && !mismatch && tags.length <= 1 &&
    (run && tagged === run || WORKHORSE_ARMS[seat] && byLocation && !tagged);
  const resultState = resultVerdict(result.text);
  const conflict = foreignRunner ? 'Runner record does not match this seat, issue or branch.' :
    tags.length > 1 ? 'result names multiple runs' : mismatch && !previous ? 'result run id differs; earlier run is not proved' : !previous && run && !tagged && !resultMatches && resultState &&
    !(resultState === 'ended' && status?.status !== 'running') ? 'result has no run id' : null;
  const started = time(status?.started), finished = time(status?.finished);
  const names = ['log.txt','events.jsonl','checks_node.txt','checks_parity.txt'];
  const writes = names.map(name => ({name, at:reader.stat(path.join(folder,name),fileSource(name))?.mtimeMs || 0}));
  const log = read('log.txt',16384);
  const evidence = [{source:'status.json', at:iso(state.mtime), run:run?.slice(0,8) || null}];
  if (result.exists) evidence.push({source:'result.txt', at:iso(result.mtime), run:tagged?.slice(0,8) || null,
    association:previous ? 'previous run, ended ' + new Date(eventTime(result.text.split(/\r?\n/).filter(l=>/all done/i.test(l)).at(-1) || '',result.mtime)).toISOString().slice(11,16) : resultMatches ? byLocation && !tagged ? 'same run directory; no run id in result' : 'matching run id' : 'association unverified'});
  for (const w of writes.filter(w => w.at)) evidence.push({source:w.name, at:iso(w.at), association:started && w.at > started ? 'after run start' : 'from an earlier run'});
  const activity = foreignRunner ? 0 : maxTime(started, ...writes.filter(w => started && w.at > started).map(w=>w.at),
    started && state.mtime > started && state.mtime, started && resultMatches && result.mtime > started && result.mtime);
  const runnerTitle = WORKHORSE_ARMS[seat] ? read('title.txt',4096).text.trim() : '';
  const title = cleanTitle(!foreignRunner && (status?.title || runnerTitle || titleFromLog(log.text, issue)), issue);
  return {issue, job:{issue,title,branch,url:REPO+'/issues/'+issue,prUrl:REPO+'/pulls?q='+encodeURIComponent('is:pr head:'+branch)},
    folder, run:foreignRunner ? null : run, started:foreignRunner ? 0 : started, finished:foreignRunner ? 0 : finished,
    activity, logAt:writes.find(w=>w.name==='log.txt')?.at, updated:maxTime(state.mtime, ...writes.map(w=>w.at)),
    status:foreignRunner ? null : status, state, result, resultState, resultMatches, previous, conflict,
    evidence:foreignRunner ? [{source:'Runner records',at:iso(state.mtime),association:'seat, issue or branch unverified'}] : evidence, byLocation,
    files:[state.exists && 'status.json', result.exists && 'result.txt', ...writes.filter(w=>w.at).map(w=>w.name)].filter(Boolean)};
}
function workhorseOutput(job, source, latest, reader) {
  if (!latest.exists || latest.unreadable) return null;
  const pointer = latest.text.trim().replace(/[\\/]/g,path.sep);
  const resolved = path.resolve(job,pointer), run = path.relative(job,resolved);
  // The original runner wrote directly to the issue's out folder.
  if (!pointer || (run && !/^\d{8}_\d{6}$/.test(run))) {
    reader.errors.add(source+'/latest.txt: expected the issue folder or one timestamped run inside it');
    return null;
  }
  const runSource = run ? source+'/'+run : source;
  if (run && !reader.directory(resolved,runSource)) return null;
  const folder = path.join(resolved,'out'), outSource = runSource+'/out';
  return reader.directory(folder,outSource) ? {folder,source:outSource} : null;
}
function readJobs(root, seat, reader, hasLaneLog = false) {
  const jobs = [], [id,,directory] = seat, base = path.join(root,directory);
  const arms = WORKHORSE_ARMS[id];
  for (const d of reader.dirs(base,!!arms && hasLaneLog,arms ? directory : undefined)) {
    if (!d.isDirectory()) continue;
    const m = /^issue-(\d+)(?:-([a-z]+))?$/i.exec(d.name), arm = m?.[2]?.toLowerCase();
    if (!m || (arms ? !arms.includes(arm) : arm)) continue;
    const p = path.join(base,d.name);
    if (!arms) jobs.push(jobInfo(p,+m[1],id,reader));
    else {
      const source = directory+'/'+d.name;
      const latest = reader.read(path.join(p,'latest.txt'),4096,false,source+'/latest.txt',true);
      const output = workhorseOutput(p,source,latest,reader);
      if (output) jobs.push(jobInfo(output.folder,+m[1],id,reader,true,arm,output.source));
      else {
        const issue = +m[1];
        jobs.push({issue, job:{issue,title:cleanTitle(null,issue),branch:branchFor(issue,id,arm),url:REPO+'/issues/'+issue},
          updated:latest.mtime, activity:0, evidence:[{source:'latest.txt',at:iso(latest.mtime),association:'run directory unverified'}],
          files:latest.exists ? ['latest.txt'] : [], conflict:'Latest run directory is missing or unverified.'});
      }
    }
  }
  return jobs;
}
function classify(info) {
  if (!info) return {state:'unknown',reason:'No runner status is available.'};
  if (info.conflict) return {state:'unknown',reason:info.conflict};
  const s = info.status?.status;
  if (info.resultMatches && s === 'running' && ['blocked','failed','waiting'].includes(info.resultState)) return {state:info.resultState,reason:safeReason(info.result.text)};
  if (s === 'running' && info.resultMatches && info.resultState === 'ended') return {state:'unknown',reason:'Run output ended; the runner has not confirmed its result.'};
  if (s === 'running') return info.started ? {state:'running',reason:null} : {state:'unknown',reason:'Runner start time is missing.'};
  if (s === 'checked_push') return {state:'finished',reason:'Checked push confirmed; runner checks passed.'};
  if (['partial','unverified','no_changes','blocked'].includes(s)) return {state:'blocked',reason:safeReason(info.status.reason) || 'Runner did not produce a checked push.'};
  if (s === 'failed') return {state:'failed',reason:safeReason(info.status.reason) || 'Runner reported a failure.'};
  if (!info.run && ['blocked','failed'].includes(info.resultState)) return {state:info.resultState,reason:safeReason(info.result.text)};
  return {state:'unknown',reason:info.state.exists ? 'Runner status is unreadable or unrecognized.' : 'Runner status is missing; text cannot prove a checked finish.'};
}

function emptyGithub() { return { lastReadAt:null, lastAttemptAt:null, ok:false, coverageComplete:false, issues:[], pulls:[], needsRyan:[], crew:{}, reviews:[], sources:Object.fromEntries(Object.keys(SOURCE_INTERVAL_MS).map(n=>[n,sourceRecord(n)])), budget:null }; }
const issueNumber = n => Number.isSafeInteger(n) && n > 0;
const branchPattern = /^(?:codex|work|opus|muse)\/issue-\d+(?:-[a-z0-9_-]+)?$/i;
function pictureLink(raw) {
  if (typeof raw !== 'string') return null;
  const link = (/^\[[^\]]*\]\(([^)]+)\)$/.exec(raw.trim()) || [null,raw.trim()])[1];
  try {
    const decoded = decodeURIComponent(link);
    if (hasLocalUser(decoded) || /(?:gh[pousr]_|github_pat_|sk-)[a-z0-9_]+/i.test(decoded)) return null;
    const u = new URL(link);
    return u.protocol === 'https:' && !u.username && !u.password && !u.search && !u.hash &&
      (u.hostname === 'github.com' && u.pathname.startsWith('/rcbailey12/voidsworn/') || u.hostname === 'raw.githubusercontent.com' && u.pathname.startsWith('/rcbailey12/voidsworn/')) ? u.href : null;
  } catch (_) { return null; }
}
function askRyan(body) {
  let fence;
  for (const line of String(body || '').split(/\r?\n/)) {
    const marker = /^\s*(`{3,}|~{3,})(.*)$/.exec(line);
    if (marker) {
      if (!fence) fence = marker[1];
      else if (marker[1][0] === fence[0] && marker[1].length >= fence.length && !marker[2].trim()) fence = undefined;
      continue;
    }
    const match = !fence && /^Ask Ryan:\s*(.*)$/.exec(line);
    if (!match) continue;
    const [raw, picture] = match[1].split(/\s*\|\s*Picture:\s*/, 2);
    const question = publicText(raw);
    if (question) return {question, picture:pictureLink(picture)};
  }
  return null;
}
function githubData(issues, pulls, comments, previous, now) {
  if (![issues,pulls,comments].every(Array.isArray)) throw Error('Invalid GitHub list');
  const data = emptyGithub();
  data.lastReadAt = iso(now); data.lastAttemptAt = iso(now); data.ok = true;
  // Standalone sanitizer: the paginated reader sets authoritative completeness per source.
  data.coverageComplete = issues.length < 100 || !!previous.coverageComplete && time(issues.at(-1)?.updated_at) <= time(previous.lastReadAt);
  data.issues = [...previous.issues]; data.pulls = [...previous.pulls]; data.crew = {...previous.crew};
  data.reviews = [...(previous.reviews || [])];
  const put = (list, item, key) => { const index=list.findIndex(x=>x[key]===item[key]); if(index<0)list.push(item);else list[index]=item; };
  const record = (seat,at,action,number) => {
    if (time(at) && (!data.crew[seat] || time(at)>time(data.crew[seat].at))) data.crew[seat]={at:iso(time(at)),action,number,url:`${REPO}/${action==='Technical review recorded'?'issues':'pull'}/${number}`};
  };
  for (const issue of issues) {
    if (!issueNumber(issue.number) || issue.pull_request) continue;
    const needsRyan = issue.state === 'open' && Array.isArray(issue.labels) && issue.labels.some(l=>(typeof l==='string'?l:l?.name)==='ryan');
    const ask = needsRyan ? askRyan(issue.body) || {question:null,picture:null} : null;
    put(data.issues,{number:issue.number,title:cleanTitle(issue.title,issue.number),state:issue.state === 'closed' ? 'closed' : issue.state === 'open' ? 'open' : 'unknown',
      updatedAt:iso(time(issue.updated_at)),closedAt:iso(time(issue.closed_at)),ask},'number');
  }
  for (const pr of pulls) {
    if (!issueNumber(pr.number) || pr.base?.repo?.full_name !== 'rcbailey12/voidsworn') continue;
    const own = pr.head?.repo?.full_name === 'rcbailey12/voidsworn', branch = own && pr.head?.ref;
    const state = pr.merged_at ? 'merged' : ['open','closed'].includes(pr.state) ? pr.state : null;
    if (branchPattern.test(branch)) put(data.pulls,{number:pr.number,branch,state,head:sha(pr.head.sha),updatedAt:iso(time(pr.updated_at)),
      mergedAt:iso(time(pr.merged_at)),url:`${REPO}/pull/${pr.number}`},'number');
    if (own && /^opus\//i.test(branch)) record('claude',pr.updated_at,'PR activity recorded',pr.number);
    if (own && /^muse\//i.test(branch)) record('muse',pr.updated_at,'PR activity recorded',pr.number);
    if (own && /^work\/issue-\d+-openai$/i.test(branch)) record('openai',pr.updated_at,'PR activity recorded',pr.number);
  }
  for (const comment of comments) {
    const m = /^https:\/\/api\.github\.com\/repos\/rcbailey12\/voidsworn\/issues\/(\d+)$/.exec(comment.issue_url || '');
    const body = String(comment.body || '');
    if (!m || !issueNumber(comment.id)) continue;
    const revision = body.startsWith('Artoo (technical review):') && /\b(?:commit|head|sha)\s*(?:[:=]|is)?\s*`?([a-f0-9]{7,40})\b/i.exec(body)?.[1]?.toLowerCase();
    const review = {id:comment.id,number:+m[1],revision:revision || null,at:iso(time(comment.updated_at))};
    data.reviews = data.reviews.filter(r=>r.id!==comment.id);
    if (body.startsWith('Artoo (technical review):')) {
      record('artoo',comment.updated_at,'Technical review recorded',+m[1]);
      if (revision) data.reviews.push(review);
    }
  }
  data.issues.sort((a,b)=>time(b.updatedAt)-time(a.updatedAt)); data.pulls.sort((a,b)=>time(b.updatedAt)-time(a.updatedAt));
  // Retain marked questions even when they fall outside the latest update window.
  data.issues = data.issues.filter((x,i)=>i<500 || x.ask); data.pulls = data.pulls.slice(0,500);
  data.reviews.sort((a,b)=>time(b.at)-time(a.at));
  data.reviews = data.reviews.slice(0,500);
  data.needsRyan = data.issues.filter(x=>x.ask).map(x=>({issue:x.number,title:x.title,url:`${REPO}/issues/${x.number}`,updatedAt:x.updatedAt,...x.ask}));
  return data;
}
function enrichJob(job, github) {
  const issue=github.issues.find(x=>x.number===job.issue);
  if (issue) { job.githubState = issue.state || 'unknown'; if (issue.state === 'closed') job.note = 'closed on GitHub; the chain still lists it'; }
  if (issue && /\(title (?:unavailable|withheld)\)$/.test(job.title)) job.title=issue.title;
  const pr=github.pulls.filter(x=>x.branch===job.branch).sort((a,b)=>time(b.updatedAt)-time(a.updatedAt))[0];
  if (pr) {
    job.prState=pr.state; job.prNumber=pr.number; job.prUrl=pr.url; job.prUpdatedAt=pr.updatedAt;
    const review = pr.head && github.reviews?.find(r=>r.number===pr.number && pr.head.startsWith(r.revision));
    if (review) job.prReviewAt = review.at;
  }
}
class GithubReadError extends Error {}
class GithubReader {
  constructor(fetcher = fetch, initial = emptyGithub(), budget = new Budget()) {
    this.fetcher = fetcher; this.data = initial; this.budget = budget; this.busy = false; this.started = null; this.pending = {};
    this.watermarks = {};
    this.data.sources ||= Object.fromEntries(Object.keys(SOURCE_INTERVAL_MS).map(n=>[n,sourceRecord(n)]));
  }
  async request(url, now) {
    if (!this.budget.spend(now)) throw new GithubReadError('Shared GitHub budget paused');
    const res = await this.fetcher(url,{method:'GET',redirect:'error',headers:{Accept:'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28','User-Agent':'voidsworn-mission-control'},signal:AbortSignal.timeout(8000)});
    this.budget.headers(res.headers,res.status,now);
    if (!res.ok) throw new GithubReadError(Number.isInteger(res.status) && res.status>=100 && res.status<=599 ? 'GitHub returned HTTP '+res.status : 'GitHub returned an HTTP error');
    let body = '', bytes = 0;
    const decoder = new TextDecoder();
    for await (const chunk of res.body) { bytes += chunk.length; if (bytes > 4*1024*1024) throw new GithubReadError('GitHub response too large'); body += decoder.decode(chunk,{stream:true}); }
    let items;
    try { items = JSON.parse(body + decoder.decode()); }
    catch (_) { throw new GithubReadError('GitHub returned invalid JSON'); }
    if (!Array.isArray(items)) throw new GithubReadError('GitHub response was not a list');
    // Build page URLs ourselves so a Link header can never send this reader elsewhere.
    const hasNext = /<[^>]+>;\s*rel="next"/.test(res.headers.get('link') || '');
    return {items, hasNext};
  }
  async update(at) {
    if (this.busy) return this.data;
    const clock = at === undefined ? Date.now : () => at;
    const now = clock();
    this.busy = true; this.started ??= now;
    const names = Object.keys(SOURCE_INTERVAL_MS), base = 'https://api.github.com/repos/rcbailey12/voidsworn/';
    try {
      for (let index = 0; index < names.length; index++) {
        const name = names[index], record = this.data.sources[name];
        const due = record.nextAttemptAt ? time(record.nextAttemptAt) : this.started + index*60000;
        if (now < due || !this.budget.canSpend(now)) continue;
        record.lastAttemptAt = iso(now); record.complete = false; record.reason = 'Reading pages';
        const watermark = this.watermarks[name];
        const since = iso(watermark ?? now-7*86400000);
        const query = name === 'questions' ? 'issues?state=open&labels=ryan&per_page=100' : name === 'issues' ? 'issues?state=all&sort=updated&direction=desc&per_page=100&since='+encodeURIComponent(since) :
          name === 'pulls' ? 'pulls?state=all&sort=updated&direction=desc&per_page=100' : 'issues/comments?sort=updated&direction=desc&per_page=100&since='+encodeURIComponent(since);
        const pending = this.pending[name] ||= {query, startedAt:clock(), items:new Map(), page:1};
        const idField = name === 'comments' ? 'id' : 'number';
        let complete = false;
        try {
          while (this.budget.canSpend(now)) {
            const result = await this.request(base+pending.query+'&page='+pending.page,now);
            for (const item of result.items) {
              const id = item?.[idField];
              if (!issueNumber(id)) continue;
              const previous = pending.items.get(id);
              if (!previous || time(item.updated_at) >= time(previous.updated_at)) pending.items.set(id,item);
            }
            pending.page++;
            const reachedPrevious = name === 'pulls' && watermark && result.items.some(x=>time(x.updated_at) && time(x.updated_at)<watermark);
            if (!result.hasNext || reachedPrevious) { complete = true; break; }
          }
          if (!complete) {
            record.reason = 'Read incomplete: '+this.budget.snapshot(now).reason;
            record.nextAttemptAt = iso(this.budget.nextAvailableAt(now));
            continue;
          }
          const completedAt = clock(), items = [...pending.items.values()];
          const knownQuestions = this.data.needsRyan;
          const merged = githubData(name==='issues' || name==='questions' ? items : [], name==='pulls' ? items : [], name==='comments' ? items : [],this.data,completedAt);
          const sources = this.data.sources;
          this.data = {...merged, sources};
          this.data.needsRyan = name==='questions' ? githubData(items,[],[],emptyGithub(),completedAt).needsRyan : knownQuestions;
          // A record can move onto a page already read. Replay from the first page's start,
          // with a second of overlap for GitHub timestamps at the start boundary.
          this.watermarks[name] = pending.startedAt-1000;
          record.lastSuccessfulReadAt = iso(completedAt); record.complete = true; record.reason = null; record.failures = 0;
          record.nextAttemptAt = iso(now + SOURCE_INTERVAL_MS[name]);
          delete this.pending[name];
        } catch (error) {
          // Keep last good values, including questions. A partial page cannot prove a zero.
          record.failures++;
          record.reason = error instanceof GithubReadError ? error.message : /^(?:Timeout|Abort)Error$/.test(error?.name) ? 'GitHub request timed out' :
            'GitHub request: '+knownError(NETWORK_ERRORS,error?.cause?.code || error?.code,'request failed');
          record.nextAttemptAt = iso(now + backoff(record.failures));
          delete this.pending[name];
        }
      }
      const sources = Object.values(this.data.sources), times = sources.map(x=>time(x.lastSuccessfulReadAt));
      this.data.lastReadAt = times.every(Boolean) ? iso(Math.min(...times)) : null;
      this.data.lastAttemptAt = iso(maxTime(...sources.map(x=>time(x.lastAttemptAt))));
      this.data.coverageComplete = this.data.sources.questions.complete;
      this.data.ok = sources.every(x=>x.complete && now-time(x.lastSuccessfulReadAt)<=x.intervalSeconds*2000);
      this.data.budget = this.budget.snapshot(now);
      return this.data;
    } finally { this.busy = false; }
  }
}

const PAGE = path.resolve(__dirname,'../../../docs/mission/index.html');
const ASSETS = Object.fromEntries([
  'artoo.svg',
  ...['artoo','claude','codex','deepseek','muse','openai'].map(name=>'crew/'+name+'.svg'),
  ...['lanes','queue','gpu','pc','github','phone'].map(name=>'icons/'+name+'.svg'),
  'ChakraPetch-SemiBold.ttf','Barlow-Regular.ttf','AzeretMono-VF.ttf',
  'fonts/BigShouldersDisplay-VF.ttf','fonts/ChakraPetch-Medium.ttf','fonts/ChakraPetch-Bold.ttf',
  'fonts/Barlow-Medium.ttf','fonts/AzeretMono-VF.ttf'
].map(file => ['/'+file,file.endsWith('.svg') ? 'image/svg+xml' : 'font/ttf']));
const RUNTIME_FILES = ['publisher.js','queue.js','budget.js','phone.js','tailscale.js','../../../docs/mission/index.html',
  ...Object.keys(ASSETS).map(route=>'../../../docs/mission'+route),'build.json'];
function buildHash(base = __dirname) {
  const hash = createHash('sha256');
  for (const name of RUNTIME_FILES) {
    hash.update(name+'\0');
    try { hash.update(fs.readFileSync(path.resolve(base,name))); } catch (_) { hash.update('<missing>'); }
    hash.update('\0');
  }
  return hash.digest('hex');
}
function buildSourceAt(base = __dirname) {
  const times = RUNTIME_FILES.filter(name=>name!=='build.json').map(name=>{
    try { return fs.statSync(path.resolve(base,name)).mtimeMs; } catch (_) { return 0; }
  });
  return times.every(Boolean) ? iso(Math.max(...times)) : null;
}
function git(repo, args) {
  const r = spawnSync('git',['--no-optional-locks','-C',repo,...args],{encoding:'utf8',windowsHide:true,timeout:5000,maxBuffer:2*1024*1024,env:{...process.env,GIT_TERMINAL_PROMPT:'0'}});
  return r.status === 0 ? r.stdout.trim() : '';
}
function sourceRevision() {
  try { const manifest=JSON.parse(fs.readFileSync(path.join(__dirname,'build.json'),'utf8')); return sha(manifest.revision); } catch (_) { return sha(git(path.resolve(__dirname,'../../..'),['rev-parse','HEAD'])); }
}
// Captured during module load, before the first scan. Disk checks never replace the loaded hash.
const LOADED_BUILD = !isMainThread && workerData?.missionScan ? workerData.build :
  {id:buildHash(),startedAt:iso(Date.now()),sourceRevision:sourceRevision(),sourceAt:buildSourceAt()};
function buildInfo(loaded = LOADED_BUILD, base = __dirname) {
  const diskId=buildHash(base), diskSourceAt=buildSourceAt(base);
  return {...loaded,diskId,diskSourceAt,stale:diskId!==loaded.id};
}
const PICTURE_TYPES = {'.png':'image/png','.jpg':'image/jpeg','.webp':'image/webp'};
const PICTURE_LIMIT = 3*1024*1024;
const STAMP_LIMIT = 512*1024;
const digest = bytes => createHash('sha256').update(bytes).digest('hex');

function pictureStamp(text) {
  let stamp;
  try { stamp = JSON.parse(text); } catch (_) { return null; }
  return sha(stamp?.source_commit) && /^[a-f0-9]{64}$/i.test(stamp.image_sha256 || '') && time(stamp.date) &&
    ['sheet built','paint proof','installed in game','cloud direction check','pre-merge capture','Ryan accepted'].includes(stamp.stage) ? stamp : null;
}
function sidecarRunLink(sidecar, info) {
  if (!info || (sidecar.issue != null && sidecar.issue !== info.issue)) return null;
  if (sidecar.run != null) return info.run && runId(sidecar.run) === info.run ? 'sidecar run id' : null;
  return issueNumber(sidecar.issue) ? 'sidecar issue' : null;
}
function pictureIndex(repo, info, reader, gitRead = git) {
  const pictures = [], runStart = info?.started || 0;
  const base = info ? reader.read(path.join(info.folder,'base_commit.txt'),256) : {text:'',mtime:0};
  const baseCommit = base.mtime >= runStart ? sha(base.text.trim()) : null;
  const diff = info ? reader.read(path.join(info.folder,'diffstat.txt'),256*1024) : {text:'',mtime:0};
  const diffPaths = new Set(diff.mtime >= runStart ? diff.text.split(/\r?\n/).map(l=>/^\s*(.+?)\s+\|/.exec(l)?.[1].replace(/\\/g,'/')).filter(Boolean) : []);
  const branch = info && gitRead(repo,['symbolic-ref','--short','HEAD']);
  const commits = new Set();
  if (info && runStart && branch === info.job.branch) {
    const args = ['log','--first-parent','--since='+iso(runStart),'--format=%H%x20%ct',info.job.branch];
    if (baseCommit) args.push('^'+baseCommit);
    for (const line of gitRead(repo,[...args,'--']).split(/\r?\n/)) {
      const [revision,seconds] = line.split(' ');
      const hash = sha(revision);
      if (hash && hash !== baseCommit && +seconds*1000 > runStart) commits.add(hash);
    }
  }
  const pushed = info && sha(info.status?.commit);
  if (pushed && runStart && info.status.branch === info.job.branch) {
    const confirmation = reader.read(path.join(info.folder,'confirmed_commit.txt'),256);
    const confirmed = info.status.status === 'checked_push' || confirmation.mtime >= runStart && sha(confirmation.text.trim()) === pushed;
    if (confirmed && +gitRead(repo,['show','-s','--format=%ct',pushed])*1000 >= runStart) {
      // The runner verifies the diff against the first parent, including on rerun merge commits.
      for (const name of gitRead(repo,['diff','--name-only','--no-renames','-z',pushed+'^1',pushed,'--']).split('\0')) diffPaths.add(name);
    }
  }
  function walk(dir) {
    for (const d of reader.dirs(dir)) {
      const file = path.join(dir,d.name);
      if (d.isDirectory()) { walk(file); continue; }
      const type = PICTURE_TYPES[path.extname(d.name).toLowerCase()];
      if (!d.isFile() || !type) continue;
      const stat = reader.stat(file);
      if (!stat || stat.size > PICTURE_LIMIT) continue;
      const stampFile = reader.read(file+'.provenance.json',STAMP_LIMIT);
      const sidecar = stampFile.size <= STAMP_LIMIT && pictureStamp(stampFile.text);
      if (!sidecar) continue;
      const stampedRevision = sha(sidecar.source_commit);
      const imageHash = reader.imageHash(file, stat);
      if (!imageHash) continue;
      if (imageHash !== sidecar.image_sha256.toLowerCase()) continue;
      const date = time(sidecar.date), relative = path.relative(repo,file).replace(/\\/g,'/');
      const link = diffPaths.has(relative) ? 'run diff' : sidecarRunLink(sidecar,info) || (commits.has(stampedRevision) ? 'run branch commit' : null);
      const association = runStart && date < runStart ? 'older' : runStart && date > runStart && link ? 'this run' : 'association unverified';
      const id = digest(repo+'\0'+relative+'\0'+imageHash);
      const pictureIssue = association==='this run' ? info.issue : issueNumber(sidecar.issue) ? sidecar.issue : null;
      reader.pictureFiles?.set(id,{file,type,imageHash,stampHash:digest(stampFile.text)});
      pictures.push({id,stage:sidecar.stage,issue:pictureIssue,
        decisionOption:pictureIssue===sidecar.issue && ['A','B'].includes(sidecar.decisionOption) ? sidecar.decisionOption : null,
        revision:sidecar.source_commit.slice(0,12)+(sidecar.source_dirty ? ' + working tree' : ''),capturedAt:iso(date),
        association,evidence:association==='this run' ? link : association==='older' ? 'captured before run start' : 'no run link proved',
        writtenAt:iso(stat.mtimeMs),installedOnPC:'not tracked',acceptedByRyan:'not tracked'});
    }
  }
  for (const dir of ['docs/shots','docs/ship_pipeline']) {
    const target=path.join(repo,dir);
    // Reject junctions on every parent, not just a final file.
    try { checkOutputParents(target); walk(target); } catch (error) { reader.error('Picture index',error); }
  }
  return pictures.sort((a,b)=>time(b.capturedAt)-time(a.capturedAt));
}

function chainJobsEnded(chain, now, jobs, github) {
  if (!chain.startedAt || now-chain.mtime < STALE_SECONDS*1000 || !chain.issues.length ||
      chain.lastIssue && !chain.issues.includes(chain.lastIssue)) return false;
  return chain.issues.every((issue,index) => {
    if (chain.jobEnds.has(index)) return true;
    const start = chain.jobStarts.get(index);
    // An earlier occurrence of an issue cannot close a repeat that has yet to start.
    if (!start && chain.issues.indexOf(issue) !== index) return false;
    const since = start || chain.startedAt;
    const job = jobs.find(job=>job.issue===issue);
    if (start && job?.started >= start-2000 && job.finished >= since && !job.conflict &&
        ['checked_push','partial','unverified','no_changes','blocked','failed','stopped'].includes(job.status?.status)) return true;
    const branch = job?.job.branch || branchFor(issue,chain.id);
    return github.issues.some(item=>item.number===issue && item.state==='closed' && time(item.closedAt)>=since) ||
      github.pulls.some(pr=>pr.branch===branch && pr.state==='merged' && time(pr.mergedAt)>=since);
  });
}

function snapshot(root, now = Date.now(), reader = new Reader(), github = emptyGithub()) {
  reader.errors.clear();
  const files = new Map(reader.dirs(root,true).filter(d=>d.isFile()).map(d=>[d.name.toLowerCase(),d.name]));
  const observed = [...files.values()].filter(name=>lanePattern.test(name)).map(name=>readChain(root,name,reader,files));
  const jobsBySeat = new Map(SEATS.map(seat=>[seat[0],readJobs(root,seat,reader,observed.some(c=>c.id===seat[0]))
    .sort((a,b)=>(b.started || b.updated)-(a.started || a.updated))]));
  const chains = queue.resolveQueue(observed,now,c=>chainJobsEnded(c,now,jobsBySeat.get(c.id),github));
  const jobFor = (issue, jobs, seat) => jobs.find(j=>j.issue===issue)?.job || {issue,title:cleanTitle(null,issue),branch:branchFor(issue,seat),url:REPO+'/issues/'+issue};
  const lanes = SEATS.map(seat => {
    const id = seat[0], own = chains.filter(c=>c.id===id), jobs = jobsBySeat.get(id);
    const recorded = own.filter(c=>c.current || c.lastIssue).sort((a,b)=>b.currentAt-a.currentAt);
    const newest = recorded.filter(c=>c.currentAt===recorded[0]?.currentAt);
    // A newer own start proves the lane's latest assignment, without cancelling older records.
    const chain = newest.length===1 ? newest[0] : null;
    const issue = chain?.current || chain?.lastIssue;
    let info = issue ? jobs.find(j=>j.issue===issue) : newest.length>1 ? null : jobs[0];
    if (chain && info?.started && info.started < chain.currentAt-2000 && !info.conflict) info = null;
    const verdict = classify(info), warnings = [];
    if (newest.length>1) { verdict.state='unknown'; verdict.reason='Several chains record starts at the same time; the current job is unknown.'; }
    const started = info?.started || chain?.currentAt || 0;
    const current = newest.length>1 ? null : info?.job || (issue ? jobFor(issue,jobs,id) : null);
    const checkout = info?.byLocation && info.run ? path.join(info.folder,'..','repo') : path.join(root,seat[2],'repo');
    const pictures = WORKHORSE_ARMS[id] && !info?.run ? [] : pictureIndex(checkout,info,reader);
    const activity = maxTime(info?.activity, ...pictures.filter(p=>p.association==='this run' && time(p.writtenAt)>started).map(p=>time(p.writtenAt)));
    const stopped = chain && ['cancelled','paused'].includes(chain.state);
    if (stopped && ['running','waiting','unknown'].includes(verdict.state)) { verdict.state='blocked'; verdict.reason=`The Board ${chain.state} this chain.`; }
    const stale = !!(current && !stopped && ['running','waiting'].includes(verdict.state) && started && now-(activity || started)>=STALE_SECONDS*1000);
    if (stale) { verdict.state='quiet'; verdict.reason='quiet '+Math.floor((now-(activity || started))/60000)+' min, process not confirmed'; }
    const claimOld = !!(current && !info?.status && started && now-started>CLAIM_SECONDS*1000);
    if (current && !info && !stopped) verdict.reason=chain?.state==='ended' ? 'The chain ended without a matching runner result.' :
      claimOld ? 'Claim not confirmed; no matching runner status after 10 minutes.' : 'Claimed, not started; no matching runner status.';
    const unknown = own.filter(c=>c.state==='unknown' || c.state==='started' && (c.missingBat || c.unreadable));
    for (const c of unknown) c.reason ||= c.missingBat ? 'chain script missing' : 'source unreadable';
    const groups = own.filter(c=>['started','linked','starting','stuck','unknown'].includes(c.state)).map(c=>{
      const afterIssue = c.state==='started' ? c.current || c.lastIssue : c.predecessorIssue;
      const afterSeat = c.predecessor && c.state!=='started' ? queue.laneId(c.predecessor) : id;
      const prior = jobsBySeat.get(afterSeat).find(j=>j.issue===afterIssue);
      const old = stamp => stamp && now-stamp >= STALE_SECONDS*1000;
      const oldEnding = c.state==='started' && c===chain && !unknown.includes(c) && old(maxTime(activity,c.mtime));
      const oldPredecessor = c.state==='linked' && old(maxTime(c.predecessorAt,prior?.activity));
      return {chain:c.name,state:unknown.includes(c) ? 'unknown' : c.state,reason:c.reason,
        after:c.predecessor || (c.waitTargets.length===1 ? c.waitTargets[0] : null),targets:c.waitTargets,
        predecessor:afterIssue ? {...jobFor(afterIssue,jobsBySeat.get(afterSeat),afterSeat)} : null,predecessorAt:iso(maxTime(c.predecessorAt,prior?.activity)),
        waitSource:c.waitSource,sourceAt:iso(maxTime(c.mtime,c.batMtime)),readyAt:iso(c.readyAt),amber:!!c.amber,notes:c.notes,
        blockedByPredecessor:!!c.blockedByPredecessor,
        attention:c.blockedByPredecessor ? 'The predecessor is also blocked.' : oldEnding ? 'Old chain has no recorded ending.' :
          oldPredecessor ? 'Old predecessor chain has no recorded ending.' : null,
        jobs:(c.state==='started' ? c.issues.slice(c.cursor+(c.current ? 1 : 0)) : c.issues).map(n=>({...jobFor(n,jobs,id)}))};
    });
    const queueState = unknown.length ? 'unknown' : 'known';
    if (recorded.length>1) warnings.push('Earlier chain start records remain listed; the latest own start is the current assignment.');
    if (unknown.length) warnings.push('queue unknown: '+[...new Set(unknown.map(c=>c.reason))].join('; '));
    if (own.some(c=>c.unreadable || c.missingBat)) warnings.push('A chain source is missing or unreadable.');
    if (!current && !own.length && !info) { warnings.push('No lane feed found.'); verdict.reason='No local run or chain has been observed.'; }
    const leftovers = jobs.filter(j=>j!==info && j.status?.status==='running' && j.activity && now-j.activity>=STALE_SECONDS*1000).map(j=>({job:j.job,lastActivityAt:iso(j.activity)}));
    // Legacy Next is a listing only. Groups retain the actual partial order and every branch.
    const next = groups.flatMap(g=>g.jobs.map(j=>({...j,chain:g.chain,queueState:g.state}))).filter(j=>j.issue!==current?.issue);
    const sourceAt = maxTime(info?.updated,...own.map(c=>c.mtime));
    return {id:seat[0],label:seat[1],state:verdict.state,runnerState:['running','checked_push','partial','unverified','no_changes','blocked','failed'].includes(info?.status?.status) ? info.status.status : 'unknown',
      stale,endedWithoutPush:!!(info?.resultMatches && info.resultState==='ended' && info.status?.status!=='checked_push'),leftovers,current,
      run:info?.run?.slice(0,8) || null,startedAt:iso(started),finishedAt:iso(info?.finished || chain?.endedAt),logAt:iso(info?.logAt),lastActivityAt:iso(activity),reason:verdict.reason,
      claim:{state:info?.status ? 'runner recorded' : claimOld ? 'not confirmed' : current ? 'claimed, not started' : 'unknown',amber:claimOld},
      next,queue:{state:queueState,label:unknown.length ? 'queue unknown' : 'recorded chains; separate chains have no implied order',reason:unknown.length ? [...new Set(unknown.map(c=>c.reason))].join('; ') : null,groups,
        history:own.filter(c=>['ended','cancelled','paused','superseded'].includes(c.state)).map(c=>({chain:c.name,state:c.state,reason:c.reason,endedAt:iso(c.endedAt),sourceAt:iso(maxTime(c.mtime,c.batMtime))}))},
      pictures,evidence:info?.evidence || [],source:{lanes:own.map(c=>c.name),runner:info ? seat[1]+' runner, issue #'+info.issue : null,files:info?.files || [],updatedAt:iso(sourceAt),refreshedAt:iso(now)},warnings};
  });
  for (const lane of lanes) for (const job of [lane.current,...lane.next,...lane.queue.groups.flatMap(g=>[g.predecessor,...g.jobs]),...lane.leftovers.map(x=>x.job)].filter(Boolean)) enrichJob(job,github);
  const {reviews, ...summary} = github;
  const publicGithub = {...summary,sources:Object.fromEntries(Object.entries(github.sources || {}).map(([name,record])=>[name,{...record,stale:!record.lastSuccessfulReadAt || now-time(record.lastSuccessfulReadAt)>record.intervalSeconds*2000}]))};
  if (chains.some(c=>c.missingBat && !['ended','cancelled','paused','superseded'].includes(c.state))) reader.errors.add('Chain script missing');
  const complete = reader.errors.size===0;
  if (complete) reader.lastSuccessfulReadAt = iso(now);
  const pcSource = {complete,lastSuccessfulReadAt:reader.lastSuccessfulReadAt,lastAttemptAt:iso(now),reason:complete ? null : [...reader.errors].join(' · ')};
  return {schemaVersion:2,generatedAt:iso(now),staleAfterSeconds:STALE_SECONDS,offlineAfterSeconds:OFFLINE_SECONDS,
    thresholds:{pcFeedSeconds:OFFLINE_SECONDS,claimWithoutRunnerSeconds:CLAIM_SECONDS,workActivitySeconds:STALE_SECONDS,githubIntervalMultiplier:2},
    build:buildInfo(),github:publicGithub,pcSource,lanes,warnings:complete ? [] : ['Some PC sources could not be read; affected rows may be unknown.']};
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

async function readPictureFile(file, limit) {
  checkOutputParents(file);
  const handle = await fs.promises.open(file, fs.constants.O_RDONLY | (fs.constants.O_NOFOLLOW || 0));
  try {
    const stat = await handle.stat();
    if (!stat.isFile() || stat.size > limit) throw Error('Picture file unavailable');
    const bytes = Buffer.alloc(stat.size+1);
    let length = 0;
    while (length < bytes.length) {
      const {bytesRead} = await handle.read(bytes,length,bytes.length-length,length);
      if (!bytesRead) break;
      length += bytesRead;
    }
    const current = await fs.promises.lstat(file);
    checkOutputParents(file);
    if (!current.isFile() || current.dev!==stat.dev || current.ino!==stat.ino || length!==stat.size) throw Error('Picture changed');
    return bytes.subarray(0,length);
  } finally { await handle.close(); }
}

function imageMatchesType(bytes, type) {
  if (type==='image/png') return bytes.subarray(0,8).toString('hex')==='89504e470d0a1a0a';
  if (type==='image/jpeg') return bytes.subarray(0,3).toString('hex')==='ffd8ff';
  return bytes.toString('ascii',0,4)==='RIFF' && bytes.toString('ascii',8,12)==='WEBP';
}

const readHeaders = { 'Cache-Control':'no-store', 'X-Content-Type-Options':'nosniff', 'Referrer-Policy':'no-referrer' };
async function servePicture(req, res, index) {
  const id = /^\/pic\/([a-f0-9]{64})$/.exec(req.url)?.[1];
  const entry = req.method==='GET' && index.get(id);
  if (!entry) { res.writeHead(404).end(); return; }
  try {
    const stamp = (await readPictureFile(entry.file+'.provenance.json',STAMP_LIMIT)).toString('utf8').replace(/^\uFEFF/,'');
    if (digest(stamp)!==entry.stampHash) { res.writeHead(404).end(); return; }
    const bytes = await readPictureFile(entry.file,PICTURE_LIMIT);
    if (!imageMatchesType(bytes,entry.type) || digest(bytes)!==entry.imageHash) { res.writeHead(404).end(); return; }
    res.writeHead(200,{...readHeaders,'Content-Type':entry.type,'Content-Length':bytes.length}).end(bytes);
  } catch (_) { res.writeHead(404).end(); }
}

function startScanWorker(opts) {
  return new Worker(__filename,{workerData:{missionScan:true,opts,build:LOADED_BUILD}});
}

function scanInWorker() {
  const {root,out} = workerData.opts;
  const reader = new Reader();
  parentPort.on('message', github => {
    reader.pictureFiles = new Map();
    try {
      const data = snapshot(root,Date.now(),reader,github);
      writeSnapshot(out,data);
      parentPort.postMessage({data,pictures:reader.pictureFiles});
    } catch (_) { parentPort.postMessage({failure:'PC snapshot could not be read or saved'}); }
  });
}

async function publishOnce(opts, githubReader) {
  const reader = new Reader();
  writeSnapshot(opts.out,snapshot(opts.root,Date.now(),reader,githubReader.data));
  await githubReader.update();
  writeSnapshot(opts.out,snapshot(opts.root,Date.now(),reader,githubReader.data));
}

function serve(opts, discover = tailscale.discover, githubReader = new GithubReader(), createScanner = startScanWorker) {
  if (opts.once) return publishOnce(opts,githubReader);
  const tailnetHost = discover().host;
  const loadedPage = fs.readFileSync(PAGE);
  const assets = Object.fromEntries(Object.keys(ASSETS).map(route=>[route,fs.readFileSync(path.join(path.dirname(PAGE),route.slice(1)))]));
  let data = {schemaVersion:2,state:'starting',generatedAt:null,build:buildInfo(),lanes:[]};
  let status = Buffer.from(JSON.stringify(data));
  let pictures = new Map(), scanner, busy = false, queued = false, closed = false, timer;
  function scanFailed(reason) {
    data = {...data,pcSource:{complete:false,lastSuccessfulReadAt:data.pcSource?.lastSuccessfulReadAt || null,lastAttemptAt:iso(Date.now()),reason}};
    status = Buffer.from(JSON.stringify(data));
    console.error(reason+'; last good snapshot kept.');
  }
  function scan() {
    if (closed) return;
    if (busy) { queued = true; return; }
    if (!scanner) {
      scanner = createScanner(opts);
      scanner.on('message', result => {
        busy = false;
        if (result.data) {
          if (result.data.pcSource && !result.data.pcSource.lastSuccessfulReadAt) {
            result.data.pcSource.lastSuccessfulReadAt = data.pcSource?.lastSuccessfulReadAt || null;
          }
          data = result.data;
          status = Buffer.from(JSON.stringify(data));
          pictures = result.pictures;
        } else scanFailed(result.failure || 'PC snapshot failed');
        if (queued) { queued = false; scan(); }
      });
      scanner.on('error', () => scanFailed('PC snapshot reader failed'));
      scanner.on('exit', () => { scanner = null; busy = false; queued = false; });
    }
    busy = true;
    scanner.postMessage(githubReader.data);
  }
  function refresh() {
    scan();
    void githubReader.update().then(scan, () => console.error('GitHub read failed; last good data kept.'));
  }
  const server = http.createServer((req, res) => {
    // Fixed routes only, never a directory server or an upload endpoint.
    const route = req.url.split('?')[0];
    if (!allowedHost(req, server.address().port, tailnetHost)) { res.writeHead(403).end('Local host required'); return; }
    if (route==='/pic' || route.startsWith('/pic/')) { void servePicture(req,res,pictures); return; }
    if (req.method !== 'GET' && req.method !== 'HEAD') { res.writeHead(405).end(); return; }
    let body, type;
    if (route==='/' || route==='/index.html') { body=loadedPage; type='text/html; charset=utf-8'; }
    else if (route==='/status.json') { body=status; type='application/json; charset=utf-8'; }
    else if (Object.hasOwn(assets,route)) { body=assets[route]; type=ASSETS[route]; }
    else { res.writeHead(404).end(); return; }
    res.writeHead(200,{...readHeaders,'Content-Type':type}).end(req.method==='HEAD' ? undefined : body);
  });
  const stop = () => server.close();
  server.on('close', () => {
    closed = true;
    clearInterval(timer);
    void scanner?.terminate();
    process.off('SIGINT',stop); process.off('SIGTERM',stop);
  });
  server.listen(opts.port, '127.0.0.1', () => {
    console.log(`Mission control: http://127.0.0.1:${server.address().port}\nLocal only. Close this window or press Ctrl+C to stop. Refresh: once a minute.`);
    process.once('SIGINT',stop); process.once('SIGTERM',stop);
    timer = setInterval(refresh,60000);
    refresh();
  });
  return server;
}

module.exports = { Reader, GithubReader, emptyGithub, githubData, cleanTitle, SEATS, parseIssues, eventTime, safeReason, snapshot, classify, jobInfo, readJobs, readChain, pictureIndex, buildHash, buildSourceAt, buildInfo, ASSETS, RUNTIME_FILES, writeSnapshot, options, serve, allowedHost, servePicture };
if (!isMainThread && workerData?.missionScan) scanInWorker();
else if (require.main === module) {
  const failed = () => { console.error('Mission control could not start or write its local snapshot. Check the port and folder access.'); process.exitCode = 1; };
  try {
    const result = serve(options(process.argv.slice(2)));
    if (result instanceof Promise) void result.catch(failed);
    else result.once('error',failed);
  } catch (_) { failed(); }
}
