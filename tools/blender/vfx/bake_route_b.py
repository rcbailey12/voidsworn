"""Issue 353, route B: the hybrid. A 128 cell Mantaflow smoke body only (no fire in the simulation, no detail noise), from
three source shapes and three seeds per effect, for the weapon impact and the ship-death flash. The hot core, the colour
ramp and the sparks are authored on top by pack_routes.py (route b), so the expensive part stays small.

blender -b -t 8 -P bake_route_b.py -- OUT [--resolution 128] [--tile 512] [--kinds impact,flash] [--seeds 3] [--cpu]

Seed n uses shape SHAPES[n % 3] (route_common.burst): "shards" (six clumps thrown out on random rays, uneven), "sphere"
(twelve clumps all round a core, a round billowing burst) and "ring" (eleven clumps thrown out in a tilted flat ring, as a
hull plate tearing open). The clumps reach about three quarters of the way to the domain wall, so the 128 cells are spent
on the gas. Writes OUT/<kind>/s<n>/smoke_NN.png (16 cells) and OUT/bake.json with the wall-clock seconds of each
simulation and render. --cpu is for a sandbox smoke test.
"""
import argparse, json, pathlib, random, sys, time
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import bpy
import route_common as rc

p = argparse.ArgumentParser(); p.add_argument('out'); p.add_argument('--resolution', type=int, default=128)
p.add_argument('--tile', type=int, default=512); p.add_argument('--kinds', default='impact,flash')
p.add_argument('--seeds', type=int, default=3); p.add_argument('--cpu', action='store_true')
a = p.parse_args(sys.argv[sys.argv.index('--') + 1:]); out = pathlib.Path(a.out); out.mkdir(parents=True, exist_ok=True)

SHAPES = ['shards', 'sphere', 'ring']
KINDS = {
    'impact': dict(reach=1.3, travel=7, on=6, more=0, dissolve=14, density=1.6),
    'flash': dict(reach=1.35, travel=9, on=8, more=3, dissolve=12, density=1.8),
}


start = time.time(); records = []
if (out / 'bake.json').exists():   # one Blender call per kind (each with its own time limit) adds to the same file
    records = [r for r in json.loads((out / 'bake.json').read_text())['records'] if r['kind'] not in a.kinds.split(',')]
for kind in a.kinds.split(','):
    cfg = KINDS[kind]
    for seed in range(a.seeds):
        shape = SHAPES[seed % len(SHAPES)]; rnd = random.Random(353 * 100 + seed * 7 + (0 if kind == 'impact' else 50))
        sc = rc.reset(); folder = out / kind / ('s%d' % seed); folder.mkdir(parents=True, exist_ok=True)
        dom, ds = rc.domain('gas_%s_%d' % (kind, seed), a.resolution, folder / 'cache', cfg['dissolve'], noise=False, vorticity=.4)
        objs = rc.burst(shape, cfg, rnd)
        print('ROUTE_B_SIM', kind, seed, shape, a.resolution, flush=True)
        sim = rc.bake(dom)
        for o in objs:
            o.hide_render = True
        print('ROUTE_B_SIM_DONE', kind, seed, round(sim, 1), flush=True)
        devices = rc.render_setup(sc, a.tile, a.cpu)
        rc.world(sc, True); rc.key_light(sc); rc.smoke_material(dom, density=5.0)   # a little denser than A: the body carries the shape alone
        r1 = rc.render_frames(sc, folder, 'smoke', True)
        cache_mb = sum(f.stat().st_size for f in (folder / 'cache').rglob('*') if f.is_file()) / 1e6
        records.append(dict(kind=kind, route='b', seed=seed, shape=shape, resolution=a.resolution, noise=False, flow='smoke only',
                            frames=16, simulation_frames=rc.FRAMES, sim_seconds=round(sim, 1), render_seconds=round(r1, 1),
                            cache_mb=round(cache_mb, 1), device=devices, tile=a.tile))
        print('ROUTE_B_DONE', json.dumps(records[-1]), flush=True)
        (out / 'bake.json').write_text(json.dumps(dict(route='b', records=records, seconds_this_call=round(time.time() - start, 1)), indent=2))
