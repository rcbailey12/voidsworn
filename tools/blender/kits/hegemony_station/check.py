"""Review measurements, not a production station approval. No external packages.

Check the built mesh measurements against the real game's exported inputs and
inspect the actual GLB, rather than treating a builder's PASS line as evidence.
"""
import hashlib
import json
from pathlib import Path
import struct
import sys
import itertools
from scale import contract


def exported_bounds(glb):
    """Accessor bounds through the actual GLB node transforms, independent of fit output."""
    identity = [[float(i == j) for j in range(4)] for i in range(4)]
    def mul(a, b):
        return [[sum(a[i][k]*b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]
    def local(node):
        if 'matrix' in node:
            return [[node['matrix'][j*4+i] for j in range(4)] for i in range(4)]
        x,y,z,w = node.get('rotation', [0,0,0,1])
        r = [[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),0],
             [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),0],
             [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y),0], [0,0,0,1]]
        for i in range(3):
            for j in range(3): r[i][j] *= node.get('scale',[1,1,1])[j]
            r[i][3] = node.get('translation',[0,0,0])[i]
        return r
    points = []
    def visit(index, parent):
        node = glb['nodes'][index]
        xf = mul(parent, local(node))
        if 'mesh' in node:
            for primitive in glb['meshes'][node['mesh']]['primitives']:
                acc = glb['accessors'][primitive['attributes']['POSITION']]
                for v in itertools.product(*zip(acc['min'], acc['max'])):
                    points.append([sum(xf[i][j]*v[j] for j in range(3))+xf[i][3] for i in range(3)])
        for child in node.get('children',[]): visit(child, xf)
    for index in glb['scenes'][glb.get('scene',0)]['nodes']: visit(index, identity)
    return [max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)]


def glb_json(path):
    with path.open('rb') as f:
        magic, version, size = struct.unpack('<III', f.read(12))
        if magic != 0x46546c67 or version != 2 or size != path.stat().st_size:
            raise ValueError('not a complete GLB 2 file')
        length, kind = struct.unpack('<II', f.read(8))
        if kind != 0x4e4f534a:
            raise ValueError('GLB has no first JSON chunk')
        return json.loads(f.read(length))


def run(out, gpu=False):
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
    original=sum(m['source_footprint_outside_vertices'] for m in fit['modules'].values())
    spill=sum(m['outside_vertices'] for m in fit['modules'].values())
    check('source plan footprint',original==0,{'source_vertices_outside_real_hex_union':original,
          'scaled_vertices_outside_live_footprint':spill,'live_footprint_integration':'PENDING; review only'})
    sizing=contract()  # Read the table and board source afresh, never the fitted range.
    span=max(exported_bounds(glb))
    check('R247 exported station range',sizing['range'][0]-.001<=span<=sizing['range'][1]+.001,
          {'GLB_long_axis':span,'target_from_table':sizing['range'],
           'live_board_one_hex':sizing['live_one_hex'],'live_board_large':sizing['live_large']})
    axes=manifest['uniform_fit']['axes']
    check('uniform proportions',max(axes)-min(axes)<1e-6 and all(abs(
          manifest['bounds']['size'][i]/manifest['uniform_fit']['source_bounds']['size'][i]-axes[i])<1e-5
          for i in range(3)),axes)
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
    collisions=[s for s in samples if s['intersecting_triangle_pairs'] or s['source_footprint_outside_vertices']]
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
          'exported joints agree with the uniformly scaled build')
    scale_nodes=[n.get('scale',[1,1,1]) for n in roots]
    check('exported uniform scale',len(scale_nodes)==1 and max(scale_nodes[0])-min(scale_nodes[0])<1e-5
          and abs(scale_nodes[0][0]-axes[0])<1e-5,scale_nodes)
    check('export geometry count',triangles==manifest['triangles']['total'],
          {'GLB':triangles,'built_scene':manifest['triangles']['total']})
    if gpu:
        from PIL import Image
        captures=json.loads((out/'captures.json').read_text())
        rows=captures['comparisons']
        # Combat classes are read from actual real-rule hull definitions, not a typed pick list.
        table=json.loads((here.parents[3]/'godot/rules/data/tables.json').read_text(encoding='utf-8'))
        expected={r['cls'] for r in table['tables']['HULLS'].values() if r['cls']!='Squadron'}
        actual={r['class'] for r in rows if r['file'].startswith('game_compare170_')}
        check('all combat classes captured',actual==expected,{'expected':sorted(expected),'captured':sorted(actual)})
        bad=[]
        for row in rows:
            picture=out/row['file']
            with Image.open(picture) as im:
                if im.size!=(1280,720) or im.convert('RGB').getextrema()==((0,0),(0,0),(0,0)): bad.append(row['file'])
            if abs(row['camera_radius']-game['camera']['radius'])>.001: bad.append(row['file']+' radius')
            for key in ('station_pixels','ship_pixels'):
                x0,y0,x1,y1=row[key]
                if x0<0 or x1>1280 or y0<78 or y1>665: bad.append(row['file']+' clipped '+key)
        check('GPU review images',not bad and captures['renderer']=='forward_plus',
              {'pictures':len(rows),'bad':bad,'renderer':captures['renderer']})
    budget=dict(triangles=triangles,primitives=len(prims),materials=len(glb.get('materials',[])),
                mesh_nodes=sum('mesh' in n for n in glb['nodes']),
                glb_bytes=(out/'station_T2_review.glb').stat().st_size,
                frame_gate='NOT RUN; production station-map gate remains outside this review-only run',
                draw_calls='NOT MEASURED; GLB primitives are potential surface draws, not GPU draw measurements')
    (out/'cost.json').write_text(json.dumps(budget,indent=2)+'\n')
    result=dict(status='PASS' if all(c['pass_'] for c in checks) else 'FAIL',
                scope='Review sheet only. Not approval for production, install or performance.',
                checks=checks,cost=budget)
    (out/'review_checks.json').write_text(json.dumps(result,indent=2)+'\n')
    return result['status']=='PASS'


if __name__=='__main__':
    try:
        success=run(Path(sys.argv[1]),'--gpu' in sys.argv)
    except (OSError,ValueError,KeyError) as exc:
        print('FAIL review inputs: '+str(exc)); success=False
    sys.exit(0 if success else 1)
