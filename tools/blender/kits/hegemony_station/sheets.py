"""Label CPU studio pictures, preserving camera170 at its original pixel size.

This is sheet layout, not the production texture bake. Every item is one
1280 x 720 picture; source renders and labels are kept beside each other.
"""
import json
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont

OUT=Path(sys.argv[1])
M=json.loads((OUT/'manifest.json').read_text())
G=json.loads((OUT/'game_inputs.json').read_text())
INK='#e8e3d8'; DIM='#b9bebf'; BG='#10161d'; BLUE='#a2c5ed'


def font(size,bold=False):
    return ImageFont.truetype('C:/Windows/Fonts/'+('arialbd.ttf' if bold else 'arial.ttf'),size)


views=[('camera170','BATTLE CAMERA 170 - FIRST READ','Studio only; full image at original pixel size.'),
       ('compare170','CAMERA 170 - BESIDE REAL CRUISER','Cruiser: real ShipView geometry at 23.2 units; neutral studio material.'),
       ('compare_low','LOW CAMERA - BESIDE REAL CRUISER','Within game zoom range. CPU studio, not a game capture.'),
       ('top','TRUE TOP - ONE SCALE','Ring gap, arm stub, bent spoke, five tower positions.'),
       ('side','TRUE SIDE - ONE SCALE','Nine core drums. Same scale as top, underside and end view.'),
       ('front','TRUE END - ONE SCALE','Five cap systems and leaning array tower; cold radiators below.'),
       ('underside','TRUE UNDERSIDE - ONE SCALE','Pressure modules and service runs; same scale as true top.'),
       ('inside','INSIDES - BUILD CHECK','Skins and liners hidden; exposure +1.5: real decks, shaft, frames and racks.'),
       ('threequarter','OVERVIEW - BUILD SHEET','Draft massing and kit. Production geometry-mask paint bake pending.')]
for name,title,note in views:
    im=Image.open(OUT/(name+'.png')).convert('RGB')
    if im.size!=(1280,720): raise ValueError('unexpected render size')
    d=ImageDraw.Draw(im)
    d.rectangle((0,0,1280,68),fill=BG)
    d.text((24,10),'station_T2  |  '+title,font=font(25,True),fill=INK)
    d.text((24,42),'FLEET STATION  /  DAMAGED  /  REVIEW ONLY',font=font(17),fill=BLUE)
    d.rectangle((0,655,1280,720),fill=BG)
    d.text((24,664),note,font=font(18),fill=INK)
    dims=M['bounds']['size']
    line='Span %.2f u | Height %.2f u | Tallest measured ship %.2f u | %s triangles | GPU gate pending' % (
        dims[0],dims[2],G['max_ship_height'],format(M['triangles']['total'],','))
    d.text((24,692),line,font=font(17),fill=DIM)
    if name in ('top','side','front','underside'):
        # Read the rendered horizontal field; all four views use this scale.
        n=10*1280/M['orthographic_scale']
        d.line((30,615,30+n,615),fill=INK,width=3)
        d.line((30,609,30,621),fill=INK,width=2)
        d.line((30+n,609,30+n,621),fill=INK,width=2)
        d.text((30,628),'10 world units',font=font(17),fill=INK)
    im.save(OUT/('sheet_'+name+'.png'))
    print('SHEET',OUT/('sheet_'+name+'.png'))

# The table is written from the same built geometry and joint data as the
# pictures. It is review material, not a claim that a ship manifest checker
# already accepts station topology.
fit=json.loads((OUT/'fit.json').read_text())
cost=json.loads((OUT/'cost.json').read_text())
lines=['# station_T2: provisional build sheet','',
       'Refs #373. Fleet station first. T2 damaged is the accepted concept (R206); '
       'this sheet is a draft awaiting the Board. No production build or live swap is approved.', '',
       'CPU studio renders only. The camera170 images use the game radius, beta and vertical field of view, '
       'at 1280 x 720 without resizing. They are not in-game captures or frame-gate evidence.', '',
       '## Design and scale','',
       'Design authority: `tools/blender/kits/hegemony_station/design.py`; Hegemony-only geometry in `parts.py`. '
       'The real BattleAPI scenario and Board.hex_world supply the seven blocked cells. No rules cells are changed. '
       'Blender uses X/Y for the plan and Z up; the OBJ comparison converts actual fitted ShipView geometry to that frame.', '',
       'Overall span %.3f x %.3f units; height %.3f units. The tallest of %d loaded hulls, including all six flagships, '
       'is %.3f units. Uniform fit factor %.6f preserves the source proportions on all three axes. '
       'The four orthographic views share a %.3f-unit horizontal field and a 10-unit scale bar.' % (
           *M['bounds']['size'],len(G['ships']),G['max_ship_height'],M['uniform_fit']['scale'],M['orthographic_scale']), '',
       'The review long axis is the minimum of the station target in `docs/playbooks/scale.md`. '
       'The check reads that table and the live `godot/render/board.gd` STATION constants independently, '
       'and measures the exported GLB. Live station sizes and scale_check KNOWN rows stay unchanged. '
       'The larger station extends outside the old seven blocked cells; footprint integration remains open before a swap.', '',
       '## Feature table','',
       '| ID | Kind | Purpose | Route | Inside triangles |',
       '|---|---|---|---|---:|']
for row in M['modules']:
    tri=fit['modules'].get(row['id'],{}).get('inside_triangles',0)
    lines.append('| %s | %s | %s | hand-built, Hegemony station kit | %d |' % (
        row['id'],row['kind'],row['purpose'],tri))
lines+=['','Six habitat modules are subdivided over eleven occupied bearing slots; slot 10 is the open gap. '
        'Four attached arms include the torn stub. The fifth arm row is the tethered outer section. '
        'Five caps are a comm array, dish pair, dome, parked maintenance boom and antenna drum. '
        'All are dead. The ring is seized. One passive arm transform carries the only animation.', '',
        '## INSIDE','',
        'Core drums carry annular decks, a service shaft, radial frames and equipment racks. Ring arcs have '
        'corridor decks, inner and outer walls, cross frames and racks. Spokes and arms carry corridor structure '
        'and service runs. Towers carry a cable trunk, frame rings and equipment. Radiator roots carry header '
        'channels. These are modelled objects, not flat closing faces. The inside view hides the skins and '
        'liners and lifts exposure 1.5 stops so the dark machinery can be inspected.', '',
        '| Break intent | Position in fitted world frame | Exposed contents |',
        '|---|---|---|',
        '| Eight core bulkhead joints | Z = '+', '.join('%.3f'%z for z in M['joints']['core'])+' | Deck rings, frames, shaft and racks |',
        '| Habitat modules | Twelve 30-degree bearing boundaries; slot 10 open | Corridor, frames and racks |',
        '| Arm modules | Root, pressure collars and berth collar | Deck, racks and pipe runs |',
        '| Tower modules | Base ring, mast rings, whole cap | Cable trunk and equipment |',
        '| Radiator banks | Header manifold | Cold channels and pump |', '',
        'Break intent and source module meshes exist. Production seam paths, torn piece export and a destruction '
        'capture proving matching insides are still pending. The review GLB joins static modules for cost inspection; '
        'it is not a destructible game asset.', '',
        '## Fit and movement','',
        'The source plan fits the real seven-cell union. After uniform scaling, %d vertices are outside '
        'the live union. No blocked cell is changed in this review run. All 49 poses across 240 seconds have '
        'zero intersections between the moving arm triangles and static structure. '
        'The intentional tether attachment is excluded from that intersection test. Discrete ' %
        sum(row['outside_vertices'] for row in fit['modules'].values()) +
        'samples do not prove a continuous sweep or the fit of every static machine. Full fit review remains pending.', '',
        'The animation is a 240-second passive rotation plus a 3-degree, 40-second swing. '
        'The ring and battery strips stay static. Board answers on issue 373: no weapons, T1 later, '
        'damage cause ambiguous to the player, dust and vented insulation under hits only. '
        'The lore bible supplies no station weapon layout; none has been invented.', '',
        '## Paint stack and budget','',
        '`stack.py` currently supplies Hegemony preview materials and schematic ambient occlusion. '
        'This is not the production mask, trim and decal stack. Frost, dust, damaged edge wear and the '
        'required extra surface detail remain production work after the sheet passes.', '',
        '%s triangles total: %s exterior, %s inside. Review GLB: %d material primitives, %d materials, '
        '%d mesh nodes, %s bytes. These are reported costs, not caps. Actual draw calls and milliseconds '
        'are unmeasured. The station-map scene gate at 1080p and 4K has not run.' % (
            format(M['triangles']['total'],','),format(M['triangles']['exterior'],','),
            format(M['triangles']['inside'],','),cost['primitives'],cost['materials'],cost['mesh_nodes'],
            format(cost['glb_bytes'],',')), '',
        '## Changed from the picture','']
lines+=['- '+change for change in M['changes']]
lines+=['- R247 replaces the vertical +1-unit fit with uniform scaling to the table minimum. '
        'No source geometry axis is stretched independently. The new size requires live footprint work before installation.', '',
        '## Review order','',
        '1. `sheet_camera170.png`, then `sheet_compare170.png`, at true pixel size.',
        '2. `sheet_compare_low.png`, beside the actual cruiser geometry.',
        '3. The true top, side, underside and end sheets at one scale, then the inside sheet.',
        '4. Board design review against the accepted beauty and plan; the sheet has no approval yet.',
        '5. After acceptance: AI shape reference, production recipe contract, full fit and paint bake, '
        'station-map game captures and scene gate, outside check, then Ryan look before install.', '']
if (OUT/'captures.json').exists():
    captures=json.loads((OUT/'captures.json').read_text())
    lines+=['## GPU comparisons','',
            'Rendered in Godot with real fitted ShipView geometry and the real camera rig. '
            'One class per picture, 1280 x 720, radius 170. Isolated studio, not the production station-map gate.', '',
            '| Class | Code | Length | Picture |','|---|---|---:|---|']
    for row in captures['comparisons']:
        lines.append('| %s | %s | %.2f | %s |' % (row['class'],row['code'],row['length'],row['file']))
(OUT/'feature_table.md').write_text('\n'.join(lines),encoding='utf-8')
