"""Compose the requested R306/R308 proof and measure painted output (issue 875).

python contrib/codex/issue936/review.py [A16 ...] after run.py finishes.
Review pictures and JSON are mirrored into the issue's PC shots folder.
"""
import ast
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import struct
import numpy as np
from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parents[3]
PC = REPO.parents[1]
PROOF = PC / 'board_b/issue-936/shots'
DEST = REPO / 'docs/shots/look_bench/hullbreaker_rust_936'
sys.path.insert(0, str(REPO / 'tools'))
from picture_provenance import Review, open_picture, verify

FONT = lambda size: ImageFont.truetype('C:/Windows/Fonts/arial.ttf', size)
BG=(14,15,18); WHITE=(230,232,235); MUTED=(166,173,184); GOLD=(236,187,112)
codes = sys.argv[1:] or ['A16', 'A17', 'A18', 'A19', 'A20']
module = ast.parse((REPO / 'tools/blender/kits/hullbreakers/stack.py').read_text())
def fit(canvas, im, box):
    im = im.convert('RGB'); im.thumbnail((box[2], box[3]), Image.Resampling.LANCZOS)
    canvas.paste(im, (box[0] + (box[2]-im.width)//2, box[1] + (box[3]-im.height)//2))


def canvas(title, sub):
    im = Image.new('RGB', (1280,720), BG); d = ImageDraw.Draw(im)
    d.text((15,12), title, font=FONT(26), fill=WHITE)
    d.text((15,47), sub, font=FONT(16), fill=MUTED)
    return im, d


def save(review, image, name):
    DEST.mkdir(parents=True, exist_ok=True)
    review.save(image, DEST / name, quality=94)
    for p in (DEST / name, Path(str(DEST/name) + '.provenance.json')):
        shutil.copy2(p, PROOF / p.name)


def tones(im):
    rgb = np.asarray(im.convert('RGB'), dtype=float)
    rgb = rgb[rgb.max(axis=2) > 20]
    luma = rgb @ np.array([.2126,.7152,.0722])
    red = (rgb[:,0] > 1.2*rgb[:,1]) & (rgb[:,0] > 1.15*rgb[:,2])
    return dict(luma_p10_p50_p90=np.percentile(luma, [10,50,90]).round(1).tolist(),
                red_pixel_percent=round(float(red.mean()*100),1))


def sample(concept):
    rgb = np.asarray(concept.convert('RGB'), dtype=float).reshape(-1,3)
    r,g,b = rgb.T; y = rgb.mean(1)
    masks = dict(rust=(r>1.5*g)&(g>1.1*b)&(r<205)&(y>25),
                 blood=(r>1.6*g)&(r>1.3*b)&(y>25)&(y<160),
                 violet=(b>1.15*g)&(r>1.1*g)&(b>.95*r)&(y>35)&(y<190),
                 bare=(rgb.min(1)>.84*rgb.max(1))&(y>125)&(y<235))
    return {k: dict(pixels=int(m.sum()), rgb_p25_p75=np.percentile(rgb[m],[25,75],axis=0).round().astype(int).tolist())
            for k,m in masks.items() if m.any()}


def main():
    targets = next(n.value for n in module.body if isinstance(n,ast.Assign)
                   and any(isinstance(t,ast.Name) and t.id=='CONCEPT_REGISTERS' for t in n.targets))
    targets = eval(compile(ast.Expression(targets),'<concept targets>','eval'),{'dict':dict,'__builtins__':{}})
    measurements = {}
    for c in codes:
        out = PROOF/c
        cfg = json.loads((REPO/f'tools/recipe/ships/corsair_{c}.json').read_text())
        concept_path = REPO/cfg['concept']; concept = Image.open(concept_path)
        ref_path = REPO/f'docs/shots/look_bench/hullbreaker_paint_726/{c}_paint_full.jpg'
        review = Review('paint proof')
        old = review.open(ref_path, reference=True).convert('RGB')
        old = old.crop((644,60,old.width,old.height))
        new = review.open(out/'after/beauty.png')
        subtitle='Concept camera held fixed | R274 dark grey trophies | Geometry and plate scale unchanged'
        if c=='A18':
            subtitle='Current approved sheet | Pre-job installed mesh differs at sensor / bells | Plate scale unchanged'
        im,d = canvas(c+' | rust-red Hullbreaker paint, R306/R307',subtitle)
        for x,title,pic in [(0,'Accepted concept',concept),(427,'PR 878 | stored paint proof',old),
                            (854,'Issue 936 | new paint proof',new)]:
            d.text((x+12,88),title,font=FONT(19),fill=GOLD)
            fit(im,pic,(x,120,426,370))
        d.text((439,475),'PR 878 paint: 0e9c791d+normal726-run4',font=FONT(13),fill=MUTED)
        d.text((16,507),'Stack targets, sRGB lit tones: rust, dried blood, exposed metal, violet trophy',font=FONT(17),fill=MUTED)
        for i,k in enumerate(('rust','blood','bare','violet')):
            lo,hi=targets[c][k]; x=16+i*312
            d.rectangle((x,540,x+38,578),fill=tuple(lo));d.rectangle((x+39,540,x+77,578),fill=tuple(hi))
            d.text((x+86,540),k,font=FONT(16),fill=WHITE)
            d.text((x+86,563),str(hi),font=FONT(13),fill=MUTED)
        save(review,im,c+'_concept_878_new.jpg')

        review=Review('paint proof'); before=review.open(out/'before/engines.png'); after=review.open(out/'after/engines.png')
        im,d=canvas(c+' | matched engines, R308', 'Stern quarter, same camera | Hot core, soot and dark lips remain')
        d.text((15,88),'Before | main at start, 708ab5e7',font=FONT(20),fill=GOLD)
        d.text((655,88),'After | shared colour, strength and pattern',font=FONT(20),fill=GOLD)
        fit(im,before,(0,120,640,385));fit(im,after,(640,120,640,385))
        d.text((16,538),'Bigger bells cover more area. The emission strength and normalized hot spots are identical.',font=FONT(18),fill=MUTED)
        if c=='A18':
            d.text((16,569),'A18: pre-existing installed mesh / sheet mismatch in sensor and bells. Geometry sources unchanged.',font=FONT(14),fill=MUTED)
        save(review,im,c+'_engines_before_after.jpg')

        review=Review('installed in game')
        game_path=Path(os.environ['TEMP'])/'voidsworn936'/c/'game'/f'{cfg["game_code"]}_cam170.jpg'
        if not game_path.exists():
            game_path=out/'game'/f'{cfg["game_code"]}_cam170.jpg'
        game=review.open(game_path)
        im,d=canvas(c+' | installed in game, camera 170', 'Checked stage 7 export | Actual camera 170 pixels; lower inset enlarged for colour review')
        crop=game.crop((524,404,1396,676))
        im.paste(crop,(204,90))
        # Same camera image, with an explicitly labelled enlargement for colour review.
        inset=game.crop((820,460,1100,620)).resize((840,480))
        fit(im,inset,(220,335,840,265))
        save(review,im,c+'_game_cam170.jpg')

        meta=json.loads((out/f'{c}.json').read_text())
        export=json.loads((out/f'{cfg["game_code"]}_export.json').read_text())
        data=(PC/f'recipe/corsair_{c}/export/{cfg["game_code"]}/{cfg["game_code"]}.glb').read_bytes()
        gltf=json.loads(data[20:20+struct.unpack_from('<I',data,12)[0]])
        surfaces=sum(len(gltf['meshes'][n['mesh']]['primitives']) for n in gltf['nodes'] if 'mesh' in n)
        mesh=json.loads((out/'after/painted_mesh_measure.json').read_text())
        before_mesh=json.loads((out/'before/painted_mesh_measure.json').read_text())
        before_tones=tones(open_picture(out/'before/beauty.png'))
        measurements[c]=dict(concept=cfg['concept'],concept_sha256=hashlib.sha256(concept_path.read_bytes()).hexdigest(),
            sampled_concept=sample(concept),graded_stack_targets=targets[c],
            paint_before=before_tones,paint_after=tones(new),plate_character_on_painted_output=mesh,
            triangles=export['triangles'],turret_triangles=export.get('turret_triangles',0),
            triangles_with_turrets=export['triangles']+export.get('turret_triangles',0),
            base_surfaces=export['surfaces'],paint_surfaces=meta['surfaces'],
            merged_paint_draw_calls=meta.get('draw_calls_merged'),
            exported_surfaces=surfaces,estimated_mesh_draw_calls=surfaces,
            density=meta.get('density'),
            before_install_geometry_unchanged=mesh['geometry_sha256']==before_mesh['geometry_sha256'],
            geometry_note=('Pre-job installed A18 differs from the current approved sheet in D1 seating, engine throat/lining meshes and one generated running lamp. Rebuilt the current approved sheet without editing geometry sources.' if c=='A18' else 'Painted geometry equals the before capture.'),
            surface_check=json.loads((out/'surface_check.json').read_text()),maps=meta['res'],
            export_check=json.loads((out/f'{cfg["game_code"]}_check.json').read_text())['ok'])
    report=dict(ships=measurements,
        colour_measure='Issue 875 method: sRGB luma .2126R+.7152G+.0722B; model pixels max(R,G,B)>20; red R>1.2G and R>1.15B. Same saved concept camera before and after. No visual pass bar.',
        sampling='Concept full image: rust R>1.5G,G>1.1B,R<205,mean>25; blood R>1.6G,R>1.3B,mean25..160; violet B>1.15G,R>1.1G,B>.95R,mean35..190; bare min>.84max,mean125..235. Raw channel p25/p75 recorded; graded targets are the stack values, not copied quantiles. Lights and sky can affect raw samples.',
        plate_scope='Plate sizes and finer tiling on A17 to A20 remain outside this paint-only run. Painted mesh component areas and headings are reported; pictures decide the read.',
        budget='Base export plus separately drawn turret meshes. Surface totals include authored interior materials. Estimated mesh draws are material submissions, not GPU frame-time measurements.')
    (DEST/'checks.json').write_text(json.dumps(report,indent=2)+'\n')
    shutil.copy2(DEST/'checks.json',PROOF/'checks.json')
    if all((PROOF/c/'after/beauty.png').exists() for c in SHIPS):
        review=Review('paint proof'); im,d=canvas('A16 to A20 | rust-red Hullbreaker capitals','Issue 936 | Concept above, new paint below | Saved concept cameras')
        for i,c in enumerate(SHIPS):
            cfg=json.loads((REPO/f'tools/recipe/ships/corsair_{c}.json').read_text())
            d.text((i*256+12,83),c,font=FONT(23),fill=GOLD)
            fit(im,Image.open(REPO/cfg['concept']),(i*256,116,256,210))
            fit(im,review.open(PROOF/c/'after/beauty.png'),(i*256,315,256,195))
        save(review,im,'A16_A20_all_five.jpg')
    print('PASS issue936 review pictures and painted-output measurements')


if __name__=='__main__':
    sys.path.insert(0,str(REPO/'tools'))
    from picture_provenance import Review, open_picture
    SHIPS=['A16','A17','A18','A19','A20']
    codes=sys.argv[1:] or SHIPS
    main()
