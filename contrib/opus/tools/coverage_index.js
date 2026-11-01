'use strict';

const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../../..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8').replace(/^\uFEFF/, '');
const compare = (a, b) => a < b ? -1 : a > b ? 1 : 0;
const isText = file => /\.(md|markdown|txt|text)$/i.test(file);

function filesUnder(folder, recursive = true) {
  const full = path.join(root, folder);
  if (!fs.existsSync(full)) return [];
  return fs.readdirSync(full, { withFileTypes: true }).flatMap(entry => {
    const file = `${folder}/${entry.name}`;
    if (entry.isDirectory()) return recursive ? filesUnder(file) : [];
    return entry.isFile() ? [file] : [];
  }).sort(compare);
}

const sources = [
  ...filesUnder('contrib/muse/reviews'),
  ...filesUnder('contrib/muse/design'),
  ...filesUnder('contrib/muse', false).filter(file => /\.md$/i.test(file)),
  ...['codex', 'chatgpt', 'qwen', 'deepseek', 'argon'].flatMap(
    folder => filesUnder(`contrib/${folder}`)),
].filter(isText).filter(file => !read(file).includes('\0'));

const findings = 'contrib/opus/FINDINGS.md';
const plans = [
  'contrib/opus/next_phase_recommendation_2026_10_31.md',
  ...filesUnder('contrib/opus/briefs'),
  'BACKLOG.md',
];
const records = [findings, ...plans, 'HANDOFF.md', 'NEXT.md', 'PROGRESS.md']
  .map(file => ({ file, lines: read(file).split(/\r?\n/) }));
const statuses = ['UNCITED', 'CITED-FINDINGS', 'CITED-PLAN', 'CITED-OTHER'];

// Preserve readable punctuation while guaranteeing ASCII in generated artifacts.
function ascii(value) {
  return value.normalize('NFKD')
    .replace(/[\u2010-\u2015\u2212]/g, '-')
    .replace(/[\u2018\u2019]/g, "'")
    .replace(/[\u201c\u201d]/g, '"')
    .replace(/\u2026/g, '...')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^\x09\x0a\x0d\x20-\x7e]/g, '?');
}
const cell = value => ascii(value).replace(/\|/g, '&#124;').replace(/[\r\n]/g, ' ');

const rows = sources.map(file => {
  const name = path.posix.basename(file);
  const stem = name.slice(0, -path.posix.extname(name).length);
  const citations = new Set();
  let inFindings = false;
  let inPlan = false;
  for (const record of records) {
    for (const line of record.lines) {
      if (!line.includes(name) && !line.includes(stem)) continue;
      // The first cell is the row ID; exclude table headers and separators.
      const row = record.file === findings && line.match(/^\s*\|\s*([^|]+?)\s*\|/);
      const id = row && row[1].trim();
      if (id && !/^id$/i.test(id) && !/^:?-+:?$/.test(id)) {
        citations.add(`FINDINGS.md: ${id}`);
        inFindings = true;
      } else {
        citations.add(path.posix.basename(record.file));
      }
      if (plans.includes(record.file)) inPlan = true;
    }
  }
  const lines = read(file).split(/\r?\n/);
  let title = '';
  for (let i = 0; i < lines.length; i++) {
    const heading = lines[i].match(/^ {0,3}#{1,6}\s+(.+?)\s*#*\s*$/);
    if (heading) { title = heading[1]; break; }
    if (lines[i].trim() && /^ {0,3}(?:=+|-+)\s*$/.test(lines[i + 1] || '')) {
      title = lines[i].trim(); break;
    }
  }
  title = ascii((title || lines[0]).trim()).slice(0, 80);
  const date = name.match(/\d{4}[-_]\d{2}[-_]\d{2}/);
  const status = inFindings ? 'CITED-FINDINGS' : inPlan ? 'CITED-PLAN'
    : citations.size ? 'CITED-OTHER' : 'UNCITED';
  return { file, title, date: date ? date[0].replace(/_/g, '-') : '',
    cited: [...citations].join('; '), status };
}).sort((a, b) => statuses.indexOf(a.status) - statuses.indexOf(b.status)
  || compare(a.file, b.file));

const counts = statuses.map(status => [status, rows.filter(row => row.status === status).length]);
const folders = [...new Set(rows.map(row => path.posix.dirname(row.file)))].sort(compare);
const output = [
  '# Outside review and audit coverage index', '',
  '| Status | Count |', '| --- | ---: |',
  ...counts.map(([status, count]) => `| ${status} | ${count} |`),
  `| TOTAL | ${rows.length} |`, '',
  '| Folder | Count |', '| --- | ---: |',
  ...folders.map(folder => `| ${folder} | ${rows.filter(row => path.posix.dirname(row.file) === folder).length} |`),
  '',
  'Folder counts use each file\'s immediate parent (no overlapping totals).',
  'Matches are case-sensitive literal substrings of the basename or stem in the specified project records, including links and prose. Dates are normalized to YYYY-MM-DD. Duplicate basenames are matched independently.',
  'FINDINGS table citations list every matching row ID. Matches outside its tables use FINDINGS.md; a prose-only FINDINGS citation falls under CITED-OTHER. Plan citations take precedence over other records, and FINDINGS row citations take precedence over plans.',
  'Titles use the first ATX or setext heading, otherwise the first line, trimmed to 80 ASCII characters. Text extensions: .md, .markdown, .txt, .text; NUL-containing files are skipped.',
  'Re-run from any working directory: node contrib/opus/tools/coverage_index.js (use the script\'s absolute path when outside the repo).',
  '', '| File | Title | Date | Cited in | Status |', '| --- | --- | --- | --- | --- |',
  ...rows.map(row => `| ${[row.file, row.title, row.date, row.cited, row.status].map(cell).join(' | ')} |`), '',
].join('\n');
const destination = path.join(root, 'contrib/opus/compute');
fs.mkdirSync(destination, { recursive: true });
fs.writeFileSync(path.join(destination, 'coverage_index.md'), ascii(output), 'ascii');
const uncited = rows.filter(row => row.status === 'UNCITED').map(row => row.file);
fs.writeFileSync(path.join(destination, 'coverage_uncited.txt'), ascii(uncited.join('\n') + (uncited.length ? '\n' : '')), 'ascii');
console.log(JSON.stringify({ counts: Object.fromEntries(counts), total: rows.length,
  folders: Object.fromEntries(folders.map(folder => [folder,
    rows.filter(row => path.posix.dirname(row.file) === folder).length])),
  first40Uncited: uncited.slice(0, 40) }, null, 2));
