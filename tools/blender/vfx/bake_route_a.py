"""Issue 353, route A: the full rebake. A 256 cell Mantaflow fire and smoke simulation with the detail noise on, for the
weapon impact and the ship-death flash, rendered as two passes per cell (lit smoke, and the fire glow on black) so the
pack can make both fire amounts (flash only; flash plus a short hot core) from one simulation.

blender -b -t 8 -P bake_route_a.py -- OUT [--resolution 256] [--tile 512] [--kinds impact,flash] [--cpu]

Writes OUT/<kind>/smoke_NN.png and fire_NN.png (16 cells each) and OUT/bake.json with the wall-clock seconds of each
simulation and each render. --cpu is for a sandbox smoke test at a tiny resolution only. Caches stay in OUT.
Pack with pack_routes.py (route a). Today's bakes (bake_death.py, bake_weapons.py) are unchanged.
"""
import argparse, json, pathlib, sys, time
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import bpy
import route_common as rc

p = argparse.ArgumentParser(); p.add_argument('out'); p.add_argument('--resolution', type=int, default=256)
p.add_argument('--tile', type=int, default=512); p.add_argument('--kinds', default='impact,flash'); p.add_argument('--cpu', action='store_true')
a = p.parse_args(sys.argv[sys.argv.index('--') + 1:]); out = pathlib.Path(a.out); out.mkdir(parents=True, exist_ok=True)

# All radial bursts (the game billboards both without a direction). The fuel burns in the first frames (the flash and the
# hot core) and the smoke dissolves fast (no lingering fire in vacuum, R88).
KINDS = {
    'impact': dict(radius=.20, speed=7.0, on=2, dissolve=14, density=1.4, temperature=3.0, fuel=1.6, burn=.9),
    'flash': dict(radius=.28, speed=8.5, on=3, dissolve=12, density=1.6, temperature=3.5, fuel=2.0, burn=.8),
}
start = time.time(); records = []
if (out / 'bake.json').exists():   # one Blender call per kind (each with its own time limit) adds to the same file
    records = [r for r in json.loads((out / 'bake.json').read_text())['records'] if r['kind'] not in a.kinds.split(',')]
for kind in a.kinds.split(','):
    cfg = KINDS[kind]; sc = rc.reset(); folder = out / kind; folder.mkdir(exist_ok=True)
    dom, ds = rc.domain('gas_' + kind, a.resolution, folder / 'cache', cfg['dissolve'], noise=True, vorticity=.35)
    ds.burning_rate = cfg['burn']; ds.flame_smoke = 1.2; ds.flame_vorticity = .6; ds.flame_ignition = 1.25; ds.flame_max_temp = 3.0
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=cfg['radius'], location=(0, 0, 0)); src = bpy.context.object
    rc.flow(src, 'BOTH', cfg['density'], cfg['speed'], on=cfg['on'], temperature=cfg['temperature'], fuel=cfg['fuel'])
    print('ROUTE_A_SIM', kind, a.resolution, flush=True)
    sim = rc.bake(dom); src.hide_render = True
    print('ROUTE_A_SIM_DONE', kind, round(sim, 1), flush=True)
    devices = rc.render_setup(sc, a.tile, a.cpu)
    rc.world(sc, True); light = rc.key_light(sc); rc.smoke_material(dom)
    r1 = rc.render_frames(sc, folder, 'smoke', True)
    rc.world(sc, False); light.hide_render = True; rc.fire_material(dom)
    r2 = rc.render_frames(sc, folder, 'fire', False)
    cache_mb = sum(f.stat().st_size for f in (folder / 'cache').rglob('*') if f.is_file()) / 1e6
    records.append(dict(kind=kind, route='a', resolution=a.resolution, noise=True, noise_scale=2, flow='fire and smoke',
                        frames=16, simulation_frames=rc.FRAMES, sim_seconds=round(sim, 1), render_seconds=round(r1 + r2, 1),
                        cache_mb=round(cache_mb, 1), device=devices, tile=a.tile))
    print('ROUTE_A_DONE', json.dumps(records[-1]), flush=True)
    (out / 'bake.json').write_text(json.dumps(dict(route='a', records=records, seconds_this_call=round(time.time() - start, 1)), indent=2))
