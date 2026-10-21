// Pack a converted hull (CODE.vb 16-byte vertices, CODE.ib uint32 triangles, CODE.hdr.json) into CODE.vsm with meshopt compression.
// usage: node vsm_pack.mjs dir CODE      (needs the meshoptimizer npm package)
// .vsm = "VSM1" | u32 header length | header JSON (padded to 4) | meshopt vertex stream | meshopt index stream
import fs from 'fs'; import path from 'path'; import { MeshoptEncoder } from 'meshoptimizer';
const [dir, code] = process.argv.slice(2); await MeshoptEncoder.ready;
const hdr = JSON.parse(fs.readFileSync(path.join(dir, code + '.hdr.json'))); const vb = new Uint8Array(fs.readFileSync(path.join(dir, code + '.vb'))); let ib = new Uint32Array(fs.readFileSync(path.join(dir, code + '.ib')).buffer.slice(0));
const n = vb.length / 16; ib = new Uint32Array(ib);
const [remap, unique] = MeshoptEncoder.reorderMesh(ib, true, true); const vb2 = new Uint8Array(unique * 16);
for (let i = 0; i < n; i++) if (remap[i] !== 0xffffffff) vb2.set(vb.subarray(i * 16, i * 16 + 16), remap[i] * 16);
const ve = MeshoptEncoder.encodeVertexBuffer(vb2, unique, 16), ie = MeshoptEncoder.encodeIndexBuffer(new Uint8Array(ib.buffer), ib.length, 4);
hdr.n = unique; hdr.vlen = ve.length; hdr.ilen = ie.length; hdr.icount = ib.length;
let hj = Buffer.from(JSON.stringify(hdr)); const pad = (4 - hj.length % 4) % 4; hj = Buffer.concat([hj, Buffer.alloc(pad, 32)]);
const head = Buffer.alloc(8); head.write('VSM1', 0); head.writeUInt32LE(hj.length, 4);
fs.writeFileSync(path.join(dir, code + '.vsm'), Buffer.concat([head, hj, Buffer.from(ve), Buffer.from(ie)]));
console.log(code, 'verts', unique, 'tris', ib.length / 3, 'raw MB', ((vb2.length + ib.length * 4) / 1e6).toFixed(1), '-> vsm MB', ((ve.length + ie.length) / 1e6).toFixed(1));
