'use strict';

// node draw_maps.js <output-directory> [before-revision]
// Draws the route diagrams as SVG. The review copies are rasterized and stamped separately.
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const repo = path.resolve(__dirname, '../../..');
const harness = path.join(repo, 'godot/campaign/test/node/env.js');
const { FILES } = require(harness);
const font = require(path.join(repo, 'tools/picture_font.json'));
const examples = [1, 2, 3];
const colors = {
  battle: '#e6ba8c', elite: '#f69082', event: '#b3a7ef',
  shipyard: '#8fd9c4', drydock: '#82cfe9', field: '#d5db98', boss: '#f7af6b',
};
const originX = 112;
const columnStep = 176;
const ink = '#edf0f7';
const faint = '#a8b6cd';
const single = '#627897';
const choice = '#79caff';
const repeat = '#fc9f87';

function git(...args) {
  return execFileSync('git', ['-C', repo, ...args]);
}

function loadMaps(oracle) {
  const sample = `
    function sampleMap(seed) {
      rndSeed(seed);
      return genSector(1 + (seed - 1) % 3);
    }
    console.log(JSON.stringify(${JSON.stringify(examples)}.map(sampleMap)));
  `;
  const loader = 'require(process.argv[1]).load(process.argv[2])';
  return JSON.parse(execFileSync(process.execPath, ['-e', loader, harness, sample], {
    env: { ...process.env, VS_ORACLE: oracle },
  }));
}

function text(label, x, y, scale, fill, align = 'left') {
  // The bundled bitmap font becomes paths, so a CPU SVG rasterizer needs no fonts.
  if (align === 'center') x -= label.length * 3 * scale;
  let pixels = '';
  for (const [index, letter] of [...label].entries()) {
    const glyph = font[letter] || font['?'];
    for (const [row, bits] of glyph.entries()) {
      for (let col = 0; col < 6; col++) {
        if (bits & (1 << (5 - col))) pixels += `M${index * 6 + col} ${row}h1v1h-1z`;
      }
    }
  }
  return `<path d="${pixels}" transform="translate(${x} ${y}) scale(${scale})" fill="${fill}"/>`;
}

function rect(x, y, w, h, radius, fill, stroke = 'none') {
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${radius}" fill="${fill}" stroke="${stroke}"/>`;
}

function panel(map, top, label) {
  const stops = new Map(map.cols.flat().map(stop => [stop.id, stop]));
  const exits = new Map([...stops.keys()].map(id => [id, []]));
  for (const [from, to] of map.edges) exits.get(from).push(stops.get(to));
  const eligible = map.cols.slice(1, 5).flat();
  const two = eligible.filter(stop => exits.get(stop.id).length === 2).length;
  const sameType = id => {
    const next = exits.get(id);
    return next.length === 2 && next[0].type === next[1].type;
  };
  const repeated = [...stops.keys()].filter(sameType).length;
  const y = stop => Math.round(top + 49 + 142 * stop.y);
  const x = stop => originX + columnStep * stop.col;
  const elements = [
    rect(32, top, 1216, 198, 16, '#141f32', '#2a3a55'),
    text(label, 51, top + 14, 2, ink),
    text(`${two}/${eligible.length} TWO EXITS IN COLS 1-4   |   SAME-TYPE FORKS: ${repeated}`, 580, top + 14, 2, faint),
  ];
  for (const [from, to] of map.edges) {
    const a = stops.get(from), b = stops.get(to);
    const edgeColor = sameType(from) ? repeat : exits.get(from).length >= 2 ? choice : single;
    elements.push(`<path d="M${x(a) + 51} ${y(a)}C${x(a) + 90} ${y(a)} ${x(b) - 90} ${y(b)} ${x(b) - 51} ${y(b)}" fill="none" stroke="${edgeColor}" stroke-width="2"/>`);
  }
  for (const stop of stops.values()) {
    const color = colors[stop.type];
    elements.push(rect(x(stop) - 51, y(stop) - 14, 102, 28, 7, '#101827', color));
    elements.push(text(stop.type.toUpperCase(), x(stop), y(stop) - 11, 2, color, 'center'));
  }
  return elements.join('\n');
}

function diagram(seed, base, before, after) {
  const code = `ROUTE-1176-${String(seed).padStart(2, '0')}`;
  const elements = [
    rect(0, 0, 1280, 700, 0, '#0c1423'),
    text(code, 34, 24, 3, ink),
    text(`SECTOR ${seed}   |   SEED ${seed}`, 34, 62, 2, faint),
    text('SECTOR MAP ROUTE CHOICES', 930, 29, 2, faint),
  ];
  const headings = ['0 START', '1', '2', '3', '4', '5 REST', '6 BOSS'];
  for (const [i, label] of headings.entries()) {
    elements.push(text(label, originX + columnStep * i, 98, 2, ink, 'center'));
  }
  elements.push(panel(before, 128, `BEFORE / MAIN ${base.slice(0, 8).toUpperCase()}`));
  elements.push(panel(after, 350, 'AFTER / ISSUE 1176 WORKING TREE'));
  for (const [i, [label, color]] of [['SINGLE EXIT', single], ['CHOICE', choice], ['SAME-TYPE FORK', repeat]].entries()) {
    const x = 34 + i * 234;
    elements.push(rect(x, 580, 28, 3, 1, color));
    elements.push(text(label, x + 38, 570, 2, ink));
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="700">\n${elements.join('\n')}\n</svg>\n`;
}

const [, , output, ref = 'origin/main'] = process.argv;
if (!output) throw new Error('Usage: node draw_maps.js <output-directory> [before-revision]');
const base = git('rev-parse', '--verify', `${ref}^{commit}`).toString().trim();
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'voidsworn-route-before-'));
try {
  for (const file of [...FILES, 'ui3d.js']) fs.writeFileSync(path.join(temp, file), git('show', `${base}:${file}`));
  const before = loadMaps(temp);
  const after = loadMaps(repo);
  fs.mkdirSync(output, { recursive: true });
  for (const [index, seed] of examples.entries()) {
    const name = `route-1176-${String(seed).padStart(2, '0')}.svg`;
    fs.writeFileSync(path.join(output, name), diagram(seed, base, before[index], after[index]));
  }
} finally {
  for (const file of [...FILES, 'ui3d.js']) fs.rmSync(path.join(temp, file), { force: true });
  fs.rmdirSync(temp);
}
