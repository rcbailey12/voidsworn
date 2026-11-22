// Issue 1774 cohesion review (R418: no caps, save the work): 128k max_tokens (model ceiling), no task budget; streams review.md, summarized thinking.md and the raw SSE stream.sse into out_1774.
// Issue 1752 / PR 1753: one Fable (claude-fable-5-2) review call through Ryan's Claude API key.
// Reads request.json next to this file, streams the answer into out\review.md as it arrives (nothing lost on a cut),
// writes out\meta.json (served model, stop reason, usage, fallbacks) and out\result.txt ending "all done".
// The key comes from VOIDSWORN_CLAUDE_API_KEY and is never printed or written.
const fs = require('fs'), path = require('path'), https = require('https');
const here = __dirname, out = path.join(here, 'out_1774');
fs.mkdirSync(out, { recursive: true });
const res = path.join(out, 'result.txt'), rev = path.join(out, 'review.md'), thk = path.join(out, 'thinking.md'), raw_sse = path.join(out, 'stream.sse');
const log = (s) => fs.appendFileSync(res, new Date().toISOString() + ' ' + s + '\r\n');
const key = process.env.VOIDSWORN_CLAUDE_API_KEY;
if (!key) { log('FAILED: VOIDSWORN_CLAUDE_API_KEY not set'); log('all done'); process.exit(2); }
const body = fs.readFileSync(path.join(here, 'request_1774.json'));
fs.writeFileSync(rev, ''); fs.writeFileSync(thk, '');
const meta = { model: null, stop_reason: null, usage: {}, fallbacks: [], errors: [] };
log('start: ' + body.length + ' bytes, key present (length ' + key.length + ')');
const req = https.request({ host: 'api.anthropic.com', path: '/v1/messages', method: 'POST', timeout: 3600000,
  headers: { 'content-type': 'application/json', 'x-api-key': key, 'anthropic-version': '2023-06-01',
    'anthropic-beta': 'server-side-fallback-2026-07-01', 'content-length': body.length } }, (r) => {
  log('http ' + r.statusCode + ' request-id ' + (r.headers['request-id'] || '?'));
  let buf = '', raw = '';
  r.setEncoding('utf8');
  r.on('data', (c) => {
    if (r.statusCode !== 200) { raw += c; return; }
    fs.appendFileSync(raw_sse, c); buf += c; let i;
    while ((i = buf.indexOf('\n')) >= 0) {
      const line = buf.slice(0, i).trim(); buf = buf.slice(i + 1);
      if (!line.startsWith('data:')) continue;
      let ev; try { ev = JSON.parse(line.slice(5)); } catch (e) { continue; }
      if (ev.type === 'message_start') { meta.model = ev.message.model; Object.assign(meta.usage, ev.message.usage); }
      else if (ev.type === 'content_block_start' && ev.content_block && ev.content_block.type === 'fallback') meta.fallbacks.push(ev.content_block);
      else if (ev.type === 'content_block_delta' && ev.delta.type === 'text_delta') fs.appendFileSync(rev, ev.delta.text);
      else if (ev.type === 'content_block_delta' && ev.delta.type === 'thinking_delta') fs.appendFileSync(thk, ev.delta.thinking);
      else if (ev.type === 'content_block_start' && ev.content_block && ev.content_block.type === 'thinking') fs.appendFileSync(thk, '\n\n---\n');
      else if (ev.type === 'message_delta') { if (ev.delta) meta.stop_reason = ev.delta.stop_reason; if (ev.usage) Object.assign(meta.usage, ev.usage); if (ev.delta && ev.delta.stop_details) meta.stop_details = ev.delta.stop_details; }
      else if (ev.type === 'error') meta.errors.push(ev.error);
    }
  });
  r.on('end', () => {
    if (r.statusCode !== 200) meta.errors.push(raw.slice(0, 4000));
    fs.writeFileSync(path.join(out, 'meta.json'), JSON.stringify(meta, null, 2));
    const u = meta.usage, cost = ((u.input_tokens || 0) * 8 + (u.output_tokens || 0) * 40) / 1e6;
    log('end: model ' + meta.model + ', stop ' + meta.stop_reason + ', in ' + u.input_tokens + ', out ' + u.output_tokens + ', about $' + cost.toFixed(2) + (meta.errors.length ? ', ERRORS see meta.json' : ''));
    log(meta.errors.length || meta.stop_reason !== 'end_turn' ? 'done FAILED' : 'done PASS');
    log('all done');
  });
});
req.on('timeout', () => { log('FAILED: timeout'); req.destroy(); });
req.on('error', (e) => { log('FAILED: ' + e.message); log('all done'); });
req.end(body);
