"""Label review renders and compare the built geometry with the accepted T2 art."""
import json
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageChops

OUT=Path(sys.argv[1]); HERE=Path(__file__).resolve().parent; REPO=HERE.parents[3]
M=json.loads((OUT/'manifest.json').read_text()); G=json.loads((OUT/'game_inputs.json').read_text())
BG='#10161d'; INK='#e8e3d8'; DIM='#b9bebf'; BLUE='#a2c5ed'
def font(size,bold=False):
    return ImageFont.truetype('C:/Windows/Fonts/'+('arialbd.ttf' if bold else 'arial.ttf'),size)
views=[('camera170','BATTLE CAMERA 170 - FIRST READ'),('compare170','CAMERA 170 - REAL CRUISER'),
       ('compare_low','LOW CAMERA - REAL CRUISER'),('top','TRUE TOP'),('side','TRUE SIDE'),
       ('front','TRUE END'),('underside','TRUE UNDERSIDE'),('inside','INSIDES - SKINS HIDDEN'),
       ('threequarter','T2 DAMAGED - OVERVIEW'),('concept_beauty','T2 DAMAGE SIDE'),
       ('damage_detail','OPEN DRUMS AND FRAMES - BUILD DETAIL')]
for name,title in views:
    im=Image.open(OUT/(name+'.png')).convert('RGB')
    if im.size!=(1280,720): raise ValueError('Unexpected render size')
    d=ImageDraw.Draw(im); d.rectangle((0,0,1280,68),fill=BG)
    d.text((24,10),'station_T2 | '+title,font=font(25,True),fill=INK)
    d.text((24,42),'FLEET STATION / RUN 5 / CPU STUDIO / REVIEW ONLY',font=font(17),fill=BLUE)
    d.rectangle((0,655,1280,720),fill=BG)
    d.text((24,664),'Upright towers; named station systems; one big window. Hanging radiator motion only.',font=font(18),fill=INK)
    d.text((24,692),'Uniform span %.2f u | Height %.2f u | %s triangles | Production paint and scene gate pending' %
           (M['bounds']['size'][0],M['bounds']['size'][2],format(M['triangles']['total'],',')),font=font(17),fill=DIM)
    if name in ('top','side','front','underside'):
        n=10*1280/M['orthographic_scale'];d.line((30,615,30+n,615),fill=INK,width=3)
        d.text((30,628),'10 world units',font=font(17),fill=INK)
    im.save(OUT/('sheet_'+name+'.png'))

for code,concept,render,title,notes in [
    ('beauty','station_T2_beauty.jpg','concept_beauty','DAMAGE SIDE - ACCEPTED CONCEPT / BUILT KIT',
     ['All five towers upright; airlocks, hatches and connected service runs.',
      'Docking gear, trussed panels and ring attitude quads; one large window.']),
    ('plan','station_T2_scale.jpg','top','DIRECTLY ABOVE - ACCEPTED CONCEPT / BUILT KIT',
     ['40-degree gap over stub arm; ring seized 30 degrees.','Three spokes, one buckled; three pods and one folded plate.'])]:
    sheet=Image.new('RGB',(1280,720),BG);d=ImageDraw.Draw(sheet)
    d.text((20,12),'station_T2 | RUN 5 | '+title,font=font(22,True),fill=INK)
    left=Image.open(REPO/'contrib/muse/design/station_concept_2026_11'/concept).convert('RGB')
    right=Image.open(OUT/(render+'.png')).convert('RGB')
    # Frame the built object at the concept's review size. These two comparison
    # panels are layout crops; native camera-170 pictures above are never cropped.
    mask=ImageChops.difference(right,Image.new('RGB',right.size,right.getpixel((0,0)))).convert('L')
    box=mask.point(lambda value:255 if value>18 else 0).getbbox()
    if box:
        x0,y0,x1,y1=box
        right=right.crop((max(0,x0-20),max(0,y0-20),min(right.width,x1+20),min(right.height,y1+20)))
    # Same viewing direction, judged from art. The concept has no calibrated lens.
    for im,x in ((left,0),(right,640)):
        pane=ImageOps.contain(im,(632,535));sheet.paste(pane,(x+(640-pane.width)//2,80+(535-pane.height)//2))
    d.text((20,52),'ACCEPTED T2 CONCEPT',font=font(18,True),fill=BLUE)
    d.text((660,52),'BUILT GEOMETRY / PREVIEW MATERIALS',font=font(18,True),fill=BLUE)
    for i,line in enumerate(notes):d.text((20,618+i*25),line,font=font(20),fill=INK)
    d.text((20,680),'Review only. Concept scale differs from R247. Camera direction matched by eye; no calibrated concept camera.',font=font(17),fill=DIM)
    sheet.save(OUT/('T2_'+code+'_compare.png'))

captures=json.loads((OUT/'captures.json').read_text())
names={'airlock':'EVA airlock + frame', 'maintenance_hatch':'Pressure hatch + wheel',
       'service_pipe':'Supply / return pipes', 'handrail':'EVA handrails + tethers',
       'viewport':'One observation window', 'thruster_quad':'Four-nozzle attitude quad',
       'docking_port':'Berth clamp + guide lens', 'cargo_crane':'Cargo crane + grapple',
       'hangar_door':'Recessed cargo bay door', 'solar_panel':'Solar cells on truss',
       'cold_radiator':'Cold radiator comb', 'radiator':'Cold radiator bank',
       'sensor_mast':'Crossed dipole sensors', 'dish_array':'Dish + feed struts',
       'cargo_pod':'Held cargo container', 'maintenance_truss':'Triangulated service truss'}
names['coolant_manifold']='Pump + coolant header'
for view in captures['details']:
    im=Image.open(OUT/view['file']).convert('RGB'); d=ImageDraw.Draw(im)
    rows=sorted(view['annotations'],key=lambda r:r['pixel'][0])
    halves=[rows[:len(rows)//2],rows[len(rows)//2:]]
    for side,half in enumerate(halves):
        for i,row in enumerate(sorted(half,key=lambda r:r['pixel'][1])):
            px,py=row['pixel']; y=112+i*125; x=12 if side==0 else 998
            edge=x+270 if side==0 else x
            d.line([(px,py),(edge+(-16 if side==0 else 16),y+18),(edge,y+18)],fill=BLUE,width=2)
            d.ellipse((px-4,py-4,px+4,py+4),fill=BLUE,outline=BG,width=1)
            d.rectangle((x,y,x+270,y+38),fill=BG)
            d.text((x+8,y+9),names[row['kind']],font=font(18,True),fill=INK)
    im.save(OUT/(Path(view['file']).stem+'_labelled.png'))

fit=json.loads((OUT/'fit.json').read_text());cost=json.loads((OUT/'cost.json').read_text())
lines=['# station_T2: run 5 purposeful station systems','',
       'Refs #373. Fleet station first. Review only; production paint and live swap remain pending.','',
       'Method: the Hegemony station kit builds the design in design.py. Review.py applies one uniform '
       'scale from docs/playbooks/scale.md, exports the review GLB, measures its actual meshes and renders '
       'the CPU sheets. Capture.gd uses real ShipView hulls and the game camera for the class comparisons.','',
       '## Scale and cost','',
       'Span %.3f x %.3f units; height %.3f. Uniform scale %.6f on every axis. Tallest of %d real loaded '
       'hulls: %.3f units. No vertical fit or axis stretch.' % (*M['bounds']['size'],M['uniform_fit']['scale'],len(G['ships']),G['max_ship_height']),'',
       '%s triangles: %s exterior and %s inside. %d GLB material primitives, %d materials, %d mesh nodes. '
       'Triangles are reported, never capped. GPU draws and station-map frame time remain unmeasured.' %
       (format(cost['triangles'],','),format(M['triangles']['exterior'],','),format(M['triangles']['inside'],','),
        cost['primitives'],cost['materials'],cost['mesh_nodes']),'',
       'The source plan fits the real seven-cell union. Uniform R247 scale overhangs that old footprint; '
       'live footprint integration remains open. Board.gd STATION constants and scale_check KNOWN rows are unchanged.','',
       '## T2 damage inventory','',
       '- Run 5, Ryan R290: all five towers upright, on the spread bridges and varied heights from run 4. Exported axis nodes measure their tilt.',
       '- Nine drums have varied heights and radii, recessed window bands, stepped shoulders and small plant fittings.',
       '- Exactly one broad observation pane. The other window bands are dark; 90 small emission markers stay sparse.',
       '- Generic pallet blocks removed. Occupied drums and ring carry wheel hatches, framed EVA airlocks and connected supply/return runs.',
       '- Arms carry corridor collars, pressure hatches and handrails. Berth ends carry clamp jaws, dark guide lenses and recessed pressure doors.',
       '- Docking-arm cranes have trussed jibs and grapples. A segmented recessed cargo bay door is on the wide docking arm.',
       '- Tower sensors have crossed dipoles and stand-offs; the communications tower carries pitted dishes and feed struts.',
       '- Six ring outriggers are triangular trusses: three solar wings, three cold radiator combs. Four main radiator banks remain.',
       '- Four attitude-control quads mount directly on the outer ring. Each has four open cold nozzles, separate lips and recessed throats.',
       '- No debris field. The three held pods and folded plate from run 3 remain attached to the structure.',
       '- Ring: 40-degree gap centred at 270 degrees over the stub arm, seized 30 degrees from service. Five sprung joint plates.',
       '- Three service spokes; the southeast tube buckles inward and below the track.',
       '- Four docking arms: three intact with deep collars, one bent half arm with exposed ribs and no collar.',
       '- Three held cargo pods: two in an arm cradle, one against the ring. One thick torn plate folded over a walkway.',
       '- Nine core drums: four shell holes plus one torn top edge. Rays through the built shell test all five apertures.',
       '- Five dead caps: cracked dome, three pitted dishes, dark beacon, frozen raised crane, buckled landing pad. All towers upright.',
       '- Four cold grooved radiator banks. Radiator 4 hangs 27 degrees open on one hinge and swings +/-3 degrees over 240 seconds.',
       '- 90 blue emission markers in six jittered two-dimensional clusters and five dull orange battery strips. No red.','',
       '## INSIDE and break intent','',
       'Whole core drums have annular decks, shaft, radial frames and equipment racks. Ring arcs have corridor '
       'decks, inner walls and cross frames. Arms and spokes contain decks and racks; the stub strips back to ribs. '
       'Towers have trunk frames and racks, radiators have manifold channels. Shell holes remove the liner too. '
       'Eight core module joints, habitat sector joints, arm collars and tower roots remain authored. '
       'The review export joins static modules; production seam paths and tear validation remain open.','',
       '| ID | Kind | Purpose | Inside triangles |','|---|---|---|---:|']
for row in M['modules']:
    lines.append('| %s | %s | %s | %d |' % (row['id'],row['kind'],row['purpose'],
                 fit['modules'].get(row['id'],{}).get('inside_triangles',0)))
lines+=['','## Detail inventory','',
        'Each row below accumulates actual vertices, faces and bounds emitted by a named kit helper. '
        'Triangle subtotals are before bevel modifiers. The overall cost above includes the evaluated bevels. '
        'Label anchors project emitted face centres into each native camera-60 view, rejecting occluded anchors '
        'by rays against the loaded station mesh. A label is a viewing aid; '
        'purpose and placement still need visual review.','',
        '| Fitting | Instances | Base triangles | Function |','|---|---:|---:|---|']
for kind in sorted({r['kind'] for r in M['detail_geometry']}):
    rows=[r for r in M['detail_geometry'] if r['kind']==kind]
    lines.append('| %s | %d | %s | %s |'%(kind,len(rows),format(sum(r['triangles'] for r in rows),','),rows[0]['purpose']))
lines+=['','## Checks and limits','',
        'All 49 sampled poses test the moving radiator against the fixed structure, excluding its own hinge contact. '
        'These samples do not certify a continuous sweep or full static fit. The scale check reads the table independently '
        'and measures the exported GLB; range_selftest alters actual GLB scales and proves rejection. '
        'Godot GPU comparisons use the real camera radius 170 and actual hulls, with two runs keeping the second. '
        'They are isolated studio evidence, not a station-map gate.','',
        '## Changes from prior sheet and concept','']
lines+=['- '+c for c in M['changes']]
lines+=['- Core drum dimensions, tower positions and heights and the observation pane are retained from run 4. '
        'The run 3 breaks, source footprint, uniform scale and slow radiator motion are preserved. Preview material only; '
        'production paint is deliberately pending.','',
        '## Review order','',
        'Camera 170 class pictures first at native size, then T2_beauty_compare.png and T2_plan_compare.png, '
        'then the five game_detail60*_labelled.png views at actual game zoom radius 60, the low camera and inside sheet. Ryan has not looked during this run. '
        'Outside check and Ryan look precede production installation.','']
(OUT/'feature_table.md').write_text('\n'.join(lines).rstrip()+'\n',encoding='utf-8')
