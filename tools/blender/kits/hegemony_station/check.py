"""Review measurements, not a production station approval. No external packages.

Check the built mesh measurements against the real game's exported inputs and
inspect the actual GLB, rather than treating a builder's PASS line as evidence.
"""
import hashlib
import json
from pathlib import Path
import struct
import sys


def glb_json(path):
    with path.open('rb') as f:
        magic, version, size = struct.unpack('<III', f.read(12))
        if magic != 0x46546c67 or version != 2 or size != path.stat().st_size:
            raise ValueError('not a complete GLB 2 file')
        length, kind = struct.unpack('<II', f.read(8))
        if kind != 0x4e4f534a:
            raise ValueError('GLB has no first JSON chunk')
        return json.loads(f.read(length))


def run(out):
    here = Path(__file__).resolve().parent
    manifest = json.loads((out/'manifest.json').read_text())
    game = json.loads((out/'game_inputs.json').read_text())
    fit = json.loads((out/'fit.json').read_text())
    glb = glb_json(out/'station_T2_review.glb')
    checks = []
    def check(name, good, evidence):
        checks.append(dict(name=name,pass_=bool(good),evidence=evidence))
        print(('PASS ' if good else 'FAIL ')+name+': '+str(evidence))
    for name, digest in manifest['scripts'].items():
        check('source '+name,hashlib.sha256((here/name).read_bytes()).hexdigest()==digest,digest)
    rows=manifest['modules']
    count=lambda kind: sum(r['kind']==kind for r in rows)
    check('core and arms',count('deck_drum')==9 and count('docking_arm')==5,
          '9 core drums; 4 attached arms including stub; 1 tethered section')
    check('towers and gap',count('tower_cap')==5 and count('bearing_track')==11,
          '5 towers, 11 of 12 bearing slots occupied')
    check('light map',manifest['lights']==dict(blue=90,battery=5),manifest['lights'])
    # The footprint comes from BattleAPI and Board.hex_world, not a typed fixture.
    cells=game['footprint']['cells']
    check('three hex columns',len({c['q'] for c in cells})>=3,len(cells))
    inside=sum(m['outside_vertices'] for m in fit['modules'].values())
    check('static footprint',inside==0,{'vertices_outside_real_hex_union':inside})
    height=manifest['bounds']['size'][2]
    check('taller than ships',height>game['max_ship_height'],
          {'station':height,'tallest_loaded_ship':game['max_ship_height'],'hulls':len(game['ships'])})
    check('flagships measured',all(any(s['faction_class'].startswith(f+'|') and
          s['length']>40 for s in game['ships']) for f in
          ('voidsworn','corsair','chorus','hegemony','ithar','deathless')),
          'all six factions include their real capital hull')
    structural={'deck_drum','habitat_arc','spoke','docking_arm','tower_cap','radiator'}
    missing=[r['id'] for r in rows if r['kind'] in structural and
             fit['modules'].get(r['id'],{}).get('inside_triangles',0)==0]
    check('modelled insides',not missing,{'modules_without_inside_geometry':missing,
          'inside_triangles':manifest['triangles']['inside']})
    samples=fit['motion_samples']
    collisions=[s for s in samples if s['intersecting_triangle_pairs'] or s['outside_vertices']]
    check('motion samples',not collisions and len(samples)==49,
          {'poses':len(samples),'bad_poses':collisions,'seconds':[0,240],
           'scope':'sampled mesh intersections; continuous sweep still pending'})
    targets=[glb['nodes'][c['target']['node']]['name'] for a in glb.get('animations',[])
             for c in a['channels']]
    check('only passive arm animates',bool(targets) and set(targets)=={'T2_tethered_arm'},targets)
    prims=[p for m in glb['meshes'] for p in m['primitives']]
    triangles=sum(glb['accessors'][p['indices']]['count']//3 for p in prims)
    light_triangles={name:sum(glb['accessors'][p['indices']]['count']//3 for p in prims
        if glb['materials'][p['material']]['name']==name) for name in ('T2_blue','T2_battery')}
    # Light fixtures are closed six-face boxes: 12 actual triangles each. This
    # detects missing emitted lights, instead of trusting the declared map.
    check('exported light geometry',light_triangles=={'T2_blue':90*12,'T2_battery':5*12},light_triangles)
    durations=[glb['accessors'][s['input']]['max'][0]-glb['accessors'][s['input']]['min'][0]
               for a in glb.get('animations',[]) for s in a['samplers']]
    check('exported motion duration',bool(durations) and all(abs(t-manifest['motion']['period'])<.01
          for t in durations),durations)
    roots=[n for n in glb['nodes'] if n.get('name')==manifest['code']]
    check('fitted joint metadata',len(roots)==1 and
          json.loads(roots[0].get('extras',{}).get('joints_json','null'))==manifest['joints'],
          'exported joints agree with the fitted build, including the vertical height fit')
    check('export geometry count',triangles==manifest['triangles']['total'],
          {'GLB':triangles,'built_scene':manifest['triangles']['total']})
    budget=dict(triangles=triangles,primitives=len(prims),materials=len(glb.get('materials',[])),
                mesh_nodes=sum('mesh' in n for n in glb['nodes']),
                glb_bytes=(out/'station_T2_review.glb').stat().st_size,
                frame_gate='NOT RUN; requires a GPU window and a station-map game scene',
                draw_calls='NOT MEASURED; GLB primitives are potential surface draws, not GPU draw measurements')
    (out/'cost.json').write_text(json.dumps(budget,indent=2)+'\n')
    result=dict(status='PASS' if all(c['pass_'] for c in checks) else 'FAIL',
                scope='CPU review sheet only. Not approval for production, install or performance.',
                checks=checks,cost=budget)
    (out/'review_checks.json').write_text(json.dumps(result,indent=2)+'\n')
    return result['status']=='PASS'


if __name__=='__main__':
    try:
        success=run(Path(sys.argv[1]))
    except (OSError,ValueError,KeyError) as exc:
        print('FAIL review inputs: '+str(exc)); success=False
    sys.exit(0 if success else 1)
