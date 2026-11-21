'use strict';
// Issue 1204 (the G-6 exit-crash class): a script-level static that holds a texture, mesh, material, shader or font
// outlives the RenderingServer at quit and crashes the exit on Windows, so every such static is dropped before the game
// quits. This standing check holds that in place:
//   1. every script listed in godot/render/static_caches.gd exists and has a static func clear_static();
//   2. every script-level static that can hold a GPU resource is named inside its own script's clear_static(), and that
//      script is on the list;
//   3. the two quit paths (main.gd quit_clean, battle.gd _quit) clear through the one list, and the battle drops the
//      ship look cache when it leaves the tree.
// A static that only ever holds plain data (numbers, text, colours, ids, weak refs, CPU images) in a script that also
// touches GPU types says so on its line: `# not GPU: <why>`. Anything else in such a script counts as GPU-holding.
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const GODOT = path.join(ROOT, 'godot');

const fails = [];
const ok = (cond, msg) => { if (!cond) fails.push(msg); };

// Types that are, or own, a GPU resource.
const GPU_TYPE = /^(Texture\w*|ImageTexture\w*|NoiseTexture\w*|\w*Mesh|MultiMesh|\w*Material\w*|Shader|Font\w*|Sky|Environment)$/;
// A script "touches GPU types" when its code names one of these (or loads a resource).
const GPU_TOKEN = /\b(Texture\w*|ImageTexture|NoiseTexture\w*|\w+Mesh\b|MultiMesh|\w*Material\w*|Shader\b|ShaderMaterial|Font\w*|FontVariation|SurfaceTool|load)\s*[.(\]:)=,]|\bMesh\b/;
// Plain declared types that can never hold a resource.
const PLAIN_TYPE = /^(int|float|bool|String|StringName|NodePath|Color|Vector\w+|Rect2\w*|Transform\w*|Basis|Quaternion|AABB|Plane|Packed\w+Array|Mutex|Semaphore|RID|Callable|Signal|Image)$/;

function walk(dir, out) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (e.name === 'addons' || e.name === 'test' || e.name === '.godot' || e.name === 'gen') continue;
      walk(p, out);
    } else if (e.name.endsWith('.gd')) out.push(p);
  }
  return out;
}

const res = p => 'res://' + path.relative(GODOT, p).replace(/\\/g, '/');
const stripComment = l => {
  // drop a trailing # comment outside strings (good enough for declarations)
  let q = null;
  for (let i = 0; i < l.length; i++) {
    const c = l[i];
    if (q) { if (c === '\\') i++; else if (c === q) q = null; }
    else if (c === '"' || c === "'") q = c;
    else if (c === '#') return l.slice(0, i);
  }
  return l;
};

// The body of `static func clear_static()`: the indented lines after its header.
function clearBody(lines) {
  const i = lines.findIndex(l => /^static func clear_static\(\)/.test(l));
  if (i < 0) return null;
  const body = [];
  for (let j = i + 1; j < lines.length; j++) {
    if (lines[j].trim() === '' || /^\s/.test(lines[j])) body.push(lines[j]);
    else break;
  }
  return body.map(stripComment).join('\n');
}

// --- 1. the list
const listPath = path.join(GODOT, 'render/static_caches.gd');
ok(fs.existsSync(listPath), 'missing godot/render/static_caches.gd');
const listSrc = fs.existsSync(listPath) ? fs.readFileSync(listPath, 'utf8') : '';
const listed = new Set();
const block = /const SCRIPTS := \[([\s\S]*?)\]/.exec(listSrc);
ok(!!block, 'static_caches.gd has no SCRIPTS list');
if (block) for (const m of block[1].matchAll(/"(res:\/\/[^"]+)"/g)) listed.add(m[1]);
for (const r of listed) {
  const f = path.join(GODOT, r.slice('res://'.length));
  if (!fs.existsSync(f)) { fails.push('listed script missing: ' + r); continue; }
  const lines = fs.readFileSync(f, 'utf8').split(/\r?\n/);
  ok(clearBody(lines) !== null, 'listed script has no static func clear_static(): ' + r);
}

// --- 2. every GPU-holding static
let holders = 0, tagged = 0;
for (const f of walk(GODOT, [])) {
  const src = fs.readFileSync(f, 'utf8');
  const lines = src.split(/\r?\n/);
  const code = lines.map(stripComment).join('\n');
  const touchesGpu = GPU_TOKEN.test(code);
  const body = clearBody(lines);
  for (let n = 0; n < lines.length; n++) {
    const line = lines[n];
    // any indentation (inner classes), typed collections like Dictionary[String, Texture2D], a trailing setter colon
    const m = /^\s*static var (\w+)\s*(?::\s*([\w]+(?:\[[\w\s,]*\])?))?\s*(?::?=\s*(.*?))?\s*:?$/.exec(stripComment(line).trimEnd());
    if (!m) continue;
    const [, name, type, initRaw] = m;
    const init = (initRaw || '').trim();
    const baseType = type ? type.replace(/\[.*$/, '') : '';
    const inner = type && type.includes('[') ? type.slice(type.indexOf('[') + 1, -1).split(',').map(t => t.trim()) : [];
    let gpu = false;
    if (type && (GPU_TYPE.test(baseType) || inner.some(t => GPU_TYPE.test(t)))) gpu = true;
    // a static built or loaded where it is declared holds whatever it made (ShaderMaterial.new(), preload, load)
    else if (/\.new\(|\bpreload\(|\bload\(/.test(init) && !(type && PLAIN_TYPE.test(baseType)) && !PLAIN_TYPE.test((/^(\w+)\.new\(/.exec(init) || [])[1] || '')) gpu = true;
    else if (type && PLAIN_TYPE.test(baseType)) gpu = false;
    else {
      // untyped, Variant, Dictionary, Array or another object type: a holder when it starts empty and its script
      // touches GPU types (a filled literal is constant data)
      const empty = init === '' || /^(\{|\[\]?|null|Array\(\)|Dictionary\(\))$/.test(init) || init === '{}';
      gpu = empty && touchesGpu;
    }
    if (!gpu) continue;
    const where = path.relative(ROOT, f).replace(/\\/g, '/') + ':' + (n + 1) + ' ' + name;
    if (/#\s*not GPU:\s*\S/.test(line)) {
      ok(!(type && GPU_TYPE.test(baseType)), where + ' is typed as a GPU resource but tagged "not GPU"');
      tagged++;
      continue;
    }
    holders++;
    if (body === null) { fails.push(where + ': its script has no static func clear_static()'); continue; }
    ok(new RegExp('\\b' + name + '\\b').test(body), where + ': not cleared in its script\'s clear_static()');
    ok(listed.has(res(f)), where + ': ' + res(f) + ' is not on the list in godot/render/static_caches.gd');
  }
}

// --- 3. the quit paths and the per-battle clear
const read = p => { const f = path.join(GODOT, p); return fs.existsSync(f) ? fs.readFileSync(f, 'utf8') : ''; };
const main = read('main/main.gd');
const battle = read('scenes/battle/battle.gd');
const fnBody = (src, header) => {
  const i = src.indexOf(header);
  if (i < 0) return '';
  const rest = src.slice(i + header.length).split(/\r?\n/);
  const out = [];
  for (const l of rest.slice(1)) { if (l.trim() === '' || /^\s/.test(l)) out.push(l); else break; }
  return out.join('\n');
};
const quitMain = fnBody(main, 'func quit_clean(');
const quitBattle = fnBody(battle, 'func _quit(');
ok(/StaticCaches\.clear_all\(\)|static_caches\.gd"\)\.clear_all\(\)/.test(quitMain), 'main.gd quit_clean does not call the shared clear (static_caches.gd clear_all)');
ok(/StaticCaches\.clear_all\(\)|static_caches\.gd"\)\.clear_all\(\)/.test(quitBattle), 'battle.gd _quit does not call the shared clear (static_caches.gd clear_all)');
ok(!/has_method\("clear_static"\)/.test(quitMain + quitBattle), 'a quit path still keeps its own clear list');
ok(/clear_look_cache\(\)/.test(fnBody(battle, 'func _exit_tree(')), 'battle.gd _exit_tree does not drop the ship look cache');

if (fails.length) {
  for (const f of fails) console.log('  ' + f);
  console.log('FAIL: ' + fails.length + ' GPU static check(s) failed');
  process.exit(1);
}
console.log('PASS: ' + holders + ' GPU-holding statics in ' + listed.size + ' listed scripts are cleared at quit (' + tagged + ' tagged not GPU)');
