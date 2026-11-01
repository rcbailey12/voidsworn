// Player-facing naming checks. Node 18+, no dependencies.
'use strict';
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const ascii = s => s.replace(/[^\x20-\x7e]/g, c => {
  if (/\s/.test(c)) return ' ';
  return '\\u' + c.charCodeAt(0).toString(16).padStart(4, '0');
});
const unescapeText = s => s.replace(/\\(u[0-9a-fA-F]{4}|x[0-9a-fA-F]{2}|\r?\n|.)/g, (_, c) => {
  if (/^[ux]/.test(c) && c.length > 1) return String.fromCharCode(parseInt(c.slice(1), 16));
  return ({ n: '\n', r: '\r', t: '\t', '\n': '', '\r\n': '' })[c] ?? c;
});

// A small lexical scanner: comments are consumed before quotes. Template
// expressions recurse into code, so identifiers and comments there stay out.
function literals(source, language = 'js') {
  const out = [];
  let i = 0;
  function code(expression = false) {
    let depth = 0;
    while (i < source.length) {
      const c = source[i];
      if (expression && c === '}' && depth === 0) { i++; return; }
      if (c === '{') depth++;
      if (c === '}') depth--;
      if ((language === 'gd' && c === '#') || (language === 'js' && source.startsWith('//', i))) {
        while (i < source.length && source[i] !== '\n') i++;
      } else if (language === 'js' && source.startsWith('/*', i)) {
        const end = source.indexOf('*/', i + 2);
        i = end < 0 ? source.length : end + 2;
      } else if (c === "'" || c === '"' || c === '`') {
        const quoteStart = i;
        const q = c;
        const triple = language === 'gd' && source.startsWith(q.repeat(3), i);
        const delimiter = triple ? q.repeat(3) : q;
        i += delimiter.length;
        let start = i;
        function emit(end) {
          const raw = source.slice(start, end);
          // JSON keys have a colon immediately after the closing quote.
          if (language !== 'json' || !/^\s*:/.test(source.slice(i))) {
            out.push({ text: unescapeText(raw), start, raw,
              wordContext: /^\s*:/.test(source.slice(i)) ||
                /(?:===|!==|==|!=|\bin|\bcase|\.(?:has|get)\s*\()\s*$/.test(source.slice(0, quoteStart)) });
          }
        }
        while (i < source.length) {
          if (source[i] === '\\') { i += 2; continue; }
          if (source.startsWith(delimiter, i)) {
            const end = i;
            i += delimiter.length;
            emit(end);
            break;
          }
          if (q === '`' && source.startsWith('${', i)) {
            emit(i);
            i += 2;
            code(true);
            start = i;
          } else i++;
        }
      } else i++;
    }
  }
  code();
  return out;
}

function cells(line) {
  // Pipes inside backtick code spans are not table delimiters.
  const result = [];
  let cell = '', ticks = false;
  for (let i = 1; i < line.length; i++) {
    const c = line[i];
    if (c === '`') ticks = !ticks;
    if (c === '|' && !ticks && line[i - 1] !== '\\') { result.push(cell.trim()); cell = ''; }
    else cell += c;
  }
  if (cell.trim()) result.push(cell.trim());
  return result;
}
const unwrap = s => s.startsWith('`') && s.endsWith('`') ? s.slice(1, -1) : s;
function display(cell) {
  const s = unwrap(cell);
  // HTML fragments and prose with apostrophes are already display text.
  const isCode = /^["'`\[]/.test(s) || /(?:[:=]\s*["'\[{]|\w+\s*\(["'])/.test(s);
  if (!isCode || s.includes('<')) return [s];
  const strings = literals(s).filter(item => !(/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(item.text) && /^\s*:/.test(s.slice(item.start + item.raw.length + 1))));
  if (!strings.length) {
    // Several inventory rows intentionally stop partway through a string.
    const partial = s.match(/(?:^|:\s*)(["'])([^\n]*)$/);
    if (partial) return [unescapeText(partial[2])];
    return null;
  }
  return strings.map(item => item.text);
}
function patterns(root = ROOT) {
  const hard = new Set(), word = new Set(), unparsed = [];
  const current = [];
  const map = fs.readFileSync(path.join(root, 'contrib/opus/compute/rename_map_final.md'), 'utf8');
  map.split(/\r?\n/).forEach((line, index) => {
    if (!line.startsWith('|')) return;
    const row = cells(line);
    if (row[0] === 'Old' || /^[- :]+$/.test(row[0])) return;
    if (row.length !== 5) { unparsed.push({ line: index + 1, row: line }); return; }
    current.push(unwrap(row[1]), ...(display(row[1]) || []));
    if (/kept/i.test(row[4]) || unwrap(row[0]) === unwrap(row[1])) return;
    const old = display(row[0]), next = display(row[1]) || [];
    if (!old) { unparsed.push({ line: index + 1, row: line }); return; }
    for (const text of old) {
      if ((/\S+\s+\S+/.test(text) || /^[A-Z]\S{5,}$/.test(text)) && !next.includes(text)) hard.add(text);
    }
  });
  const bible = fs.readFileSync(path.join(root, 'contrib/opus/compute/lore_bible_r8.md'), 'utf8');
  const section = bible.match(/^### 1\.2\b[^\n]*\n([\s\S]*?)(?=^### |$(?![\s\S]))/m);
  if (!section) throw new Error('Missing shared vocabulary section');
  let column = -1, sayColumn = -1;
  for (const line of section[1].split(/\r?\n/)) {
    if (!line.startsWith('|')) continue;
    const row = cells(line);
    if (row.includes('Never say')) { column = row.indexOf('Never say'); sayColumn = row.indexOf('Say'); continue; }
    if (column < 0 || !row[column] || /^[- :]+$/.test(row[column])) continue;
    if (sayColumn >= 0 && row[sayColumn]) current.push(unwrap(row[sayColumn]));
    for (const text of row[column].split(',')) word.add(unwrap(text.trim()));
  }
  return { hard: [...hard].filter(text => !current.some(cell => cell.includes(text))), word: [...word], unparsed };
}
function filesOf(file) {
  if (/(?:^|\/)(?:test|oracle)(?:\/|$)/.test(file.replace(/\\/g, '/'))) return [];
  if (!fs.existsSync(file)) return [];
  if (fs.statSync(file).isFile()) return /\.(js|gd|json)$/.test(file) || path.basename(file) === 'head.html' ? [file] : [];
  return fs.readdirSync(file).sort().flatMap(name => filesOf(path.join(file, name)));
}
function scan(files, pats, allow = {}, root = ROOT) {
  const hits = [];
  const escaped = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  // Explicit noun exceptions: never add the generic plural suffix to warp
  // phrases. In particular, "warps" and "warped" are legal verbs.
  const warpNouns = ['warp', 'the Warp', 'warp drive', 'drop out of warp'];
  const rules = pats.hard.map(pattern => ({ type: 'HARD', pattern, re: new RegExp(escaped(pattern), 'g') }))
    .concat(pats.word.map(pattern => ({ type: 'WORD', pattern, re: new RegExp('\\b' + escaped(pattern) + (warpNouns.includes(pattern) ? '' : 's?') + '\\b', 'gi') })));
  for (const target of files) {
    const file = path.relative(root, target).replace(/\\/g, '/');
    const source = fs.readFileSync(target, 'utf8');
    let strings;
    if (target.endsWith('.html')) {
      // Hide comments and non-visible script/style contents without moving offsets.
      const visible = source.replace(/<!--[\s\S]*?-->|<(script|style)\b[^>]*>[\s\S]*?<\/\1\s*>/gi, s => s.replace(/[^\n]/g, ' '));
      strings = [...visible.matchAll(/(?:^|>)([^<]+)/g)].map(m => ({ text: m[1], start: m.index + m[0].length - m[1].length, raw: m[1] }));
    } else strings = literals(source, path.extname(target).slice(1));
    for (const item of strings) for (const rule of rules) {
      if (rule.type === 'WORD' && (item.wordContext || (!target.endsWith('.html') && /^[a-z0-9_.-]+$/.test(item.text)))) continue;
      if (Object.entries(allow).some(([sub, list]) => file.includes(sub.replace(/\\/g, '/')) && list.includes(rule.pattern))) continue;
      rule.re.lastIndex = 0;
      for (const match of item.text.matchAll(rule.re)) {
        // Translate decoded offsets back to source offsets, including escapes.
        let offset = 0;
        while (offset < item.raw.length && unescapeText(item.raw.slice(0, offset)).length < match.index) offset++;
        const line = source.slice(0, item.start + offset).split('\n').length;
        const start = Math.max(0, Math.min(match.index - 30, item.text.length - 60));
        hits.push({ file, line, type: rule.type, pattern: rule.pattern, snippet: item.text.slice(start, start + 60).replace(/\s+/g, ' ') });
      }
    }
  }
  return hits.sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line || a.pattern.localeCompare(b.pattern));
}
function main(args) {
  const pats = patterns();
  const allowPath = path.join(__dirname, 'naming_lint_allow.json');
  const allow = fs.existsSync(allowPath) ? JSON.parse(fs.readFileSync(allowPath, 'utf8')) : {};
  const targets = args.filter(a => a !== '--json');
  const defaults = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js', 'campaign3d.js', 'ui3d.js', 'main3d.js', 'head.html', 'godot'];
  const files = [...new Set((targets.length ? targets : defaults).flatMap(t => filesOf(path.resolve(ROOT, t))))];
  const hits = scan(files, pats, allow);
  for (const row of pats.unparsed) console.error(ascii('Unparsed rename row ' + row.line + ': ' + row.row));
  if (args.includes('--json')) console.log(JSON.stringify(hits, null, 2).replace(/[^\x00-\x7f]/g, c => '\\u' + c.charCodeAt(0).toString(16).padStart(4, '0')));
  else {
    for (const h of hits) console.log(ascii(`${h.file}:${h.line}  ${h.type}  ${h.pattern}  ->  ${h.snippet}`));
    console.log(`naming_lint_game: ${hits.filter(h => h.type === 'HARD').length} hard, ${hits.filter(h => h.type === 'WORD').length} word, ${files.length} files scanned`);
  }
  process.exitCode = hits.some(h => h.type === 'HARD') ? 1 : 0;
}
module.exports = { literals, patterns, scan, filesOf };
if (require.main === module) main(process.argv.slice(2));
