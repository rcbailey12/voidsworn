// Renders the game's synthesised sound cues (sfx.js SFX.CUES, the same offline code the browser runs on the first click)
// into Ogg files for Godot: godot/audio/synth/<cue>_<n>.ogg, plus godot/audio/cues.json (the cue table: bus, level,
// voice caps, gaps, pitch jitter, and the recorded-clip layers from SFX.MAP).
// Run once after a sound change (sandbox or PC):
//   npm install node-web-audio-api   (in any folder, then point NODE_PATH at its node_modules)
//   node godot/audio/build/render_synth.js <repo root>
const fs = require('fs'), path = require('path'), vm = require('vm'), cp = require('child_process');
const WA = require('node-web-audio-api');
const repo = path.resolve(process.argv[2] || '.');
const out = path.join(repo, 'godot/audio/synth');
fs.mkdirSync(out, { recursive: true });
const ctx = { console, Math, Float32Array, Uint8Array, Promise, setTimeout, G: { sfxOn: true, mobile: false }, META: {}, OfflineAudioContext: WA.OfflineAudioContext };
ctx.window = { OfflineAudioContext: WA.OfflineAudioContext };
vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(repo, 'sfx.js'), 'utf8') + '\n;this.SFX=SFX;', ctx);
const SFX = ctx.SFX;
// a context for buffers and the noise tables (the kit only needs createBuffer here)
const host = new WA.OfflineAudioContext(1, 32000, SFX.SR);
SFX.ctx = host; SFX.noise = SFX._makeNoise(host);
function wav(file, chans, SR) {
  const n = chans[0].length, ch = chans.length, b = Buffer.alloc(44 + n * ch * 2);
  b.write('RIFF', 0); b.writeUInt32LE(36 + n * ch * 2, 4); b.write('WAVEfmt ', 8); b.writeUInt32LE(16, 16); b.writeUInt16LE(1, 20); b.writeUInt16LE(ch, 22);
  b.writeUInt32LE(SR, 24); b.writeUInt32LE(SR * ch * 2, 28); b.writeUInt16LE(ch * 2, 32); b.writeUInt16LE(16, 34); b.write('data', 36); b.writeUInt32LE(n * ch * 2, 40);
  let o = 44; for (let i = 0; i < n; i++) for (let k = 0; k < ch; k++) { b.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(chans[k][i] * 32767))), o); o += 2; }
  fs.writeFileSync(file, b);
}
(async () => {
  const table = {}, tmp = path.join(out, '_tmp.wav');
  for (const name of Object.keys(SFX.CUES)) {
    const cue = SFX.CUES[name], m = SFX.MAP[name];
    const e = { bus: cue.bus, g: cue.g, max: cue.max || 4, gap: cue.gap || 0, defer: cue.defer || 0, pri: cue.pri || 1, pj: cue.pj == null ? 0.03 : cue.pj, spj: cue.spj == null ? 0.07 : cue.spj,
      salvo: cue.salvo || null, tail: cue.tail || 1, duck: cue.duck || 0, layers: m ? m.map(L => L.s ? { s: L.s, g: L.g == null ? 1 : L.g, r: L.r || 1, d: L.d || 0, pj: L.pj == null ? null : L.pj } : { syn: 1, g: L.g == null ? 1 : L.g }) : [], synth: [] };
    const needSyn = !m || m.some(L => L.syn) || true; // render every synth take: a clip that fails to load falls back to it, as in the game
    if (needSyn) {
      try {
        const bufs = await SFX._render(name, WA.OfflineAudioContext);
        bufs.forEach((b, i) => {
          const chans = []; for (let k = 0; k < b.numberOfChannels; k++) chans.push(b.getChannelData(k));
          wav(tmp, chans, b.sampleRate);
          const f = `${name}_${i}.ogg`;
          cp.execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-i', tmp, '-c:a', 'libvorbis', '-q:a', '4', path.join(out, f)]);
          e.synth.push(f);
        });
      } catch (err) { console.warn('render', name, err.message); }
    }
    table[name] = e;
  }
  try { fs.unlinkSync(tmp); } catch (x) {}
  fs.writeFileSync(path.join(repo, 'godot/audio/cues.json'), JSON.stringify(table, null, 1));
  console.log('cues', Object.keys(table).length, 'synth files', Object.values(table).reduce((a, e) => a + e.synth.length, 0));
})();
