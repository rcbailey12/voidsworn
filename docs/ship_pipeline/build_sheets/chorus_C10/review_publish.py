"""Compose C10 v7 review pictures and current evidence.

python <this file> TEMP_OUTPUT_ROOT
Requires the three review_capture.py states, build.py renders, layout and recipe
checks in TEMP_OUTPUT_ROOT. All pictures retain their own source provenance.
"""
import sys, os, json, shutil, hashlib, struct
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageFilter
import numpy as np
ROOT=next(p for p in Path(__file__).resolve().parents if (p/'tools/picture_provenance.py').is_file()); T=Path(sys.argv[1]); R=T/'renders'; L=T/'layout'; D=ROOT/'docs/ship_pipeline/build_sheets/chorus_C10'
sys.path.insert(0,str(ROOT/'tools'))
from picture_provenance import Review
D.mkdir(exist_ok=True, parents=True)
P=Review('sheet built')
BG='#171d26'; FG='#eee9dd'; DIM='#b7c0c9'; ACC='#e8b56b'
def font(n): return ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
def canvas(title, sub):
 im=Image.new('RGB',(1280,720),BG); d=ImageDraw.Draw(im)
 d.text((18,12),title,font=font(29),fill=FG); d.text((18,50),sub,font=font(17),fill=DIM)
 return im

def tile(im,src,box,crop=None,rotate=False):
 pic=P.open(src).convert('RGBA')
 if crop: pic=pic.crop(crop)
 if rotate: pic=pic.transpose(Image.Transpose.ROTATE_90)
 base=Image.new('RGBA',pic.size,BG);base.alpha_composite(pic)
 pic=ImageOps.contain(base.convert('RGB'),(box[2]-box[0],box[3]-box[1]),Image.Resampling.LANCZOS)
 im.paste(pic,(box[0]+(box[2]-box[0]-pic.width)//2,box[1]+(box[3]-box[1]-pic.height)//2))

def save(im,name): P.save(im,D/name,quality=93)
def label(im,xy,s): ImageDraw.Draw(im).text(xy,s,font=font(20),fill=ACC)
# Refresh the standard views, with readable code, stage and revision on every page.
for name in ('side','top','underside','bow','stern','cutaway','threequarter'):
 im=canvas('C10 | Ninefold Maw | v7',name+' | sheet built, unpainted | issue 921 / R306 | Blender CPU')
 tile(im,L/(name+'.png'),(18,85,1262,594));save(im,name+'.jpg')
for name in ('fit_view','cells','side_by_side'):
 im=canvas('C10 | v7 | '+name.replace('_',' '),'Sheet built, unpainted | current issue 921 geometry | CPU')
 tile(im,L/(name+'.jpg'),(16,80,1264,594));save(im,name+'.jpg')
for name in ('bioplasma','tendril','spores'):
 im=canvas('C10 | v7 | '+name,'Sheet built, unpainted | visible weapon organ | CPU')
 tile(im,R/('weapon_'+name+'.png'),(16,80,1264,594));save(im,'weapon_'+name+'.jpg')
# Exact concept camera, unchanged from the C10 fitted camera file.
for state in ('before','after'):
 im=canvas('C10 | '+state.upper()+' | concept camera',('main 51ec81bb' if state=='before' else 'v7 working design / R306')+' | sheet built, unpainted | same lens, light and framing')
 tile(im,T/'chorus_C10'/state/'concept.png',(0,80,1280,594));save(im,'C10_'+state+'_concept.jpg')
# One item, concept, main and revision, whole ship and an exposing mouth view.
im=canvas('C10 | Ninefold Maw | concept, main, revision','R306: folded flesh lips | original main and current CPU sheet build | same camera and light')
concept=ROOT/'contrib/muse/design/concept_round8b_2026_11/chorus_C10_beauty.jpg'
for i,(text,src) in enumerate((('CONCEPT | accepted R204',concept),('BEFORE | main 51ec81bb',T/'chorus_C10/before/concept.png'),('AFTER | v7 working',T/'chorus_C10/after/concept.png'))):
 x=16+i*422;label(im,(x,81),text)
 if i==0:
  pic=P.open(src,reference=True).convert('RGB');pic=ImageOps.contain(pic,(406,255),Image.Resampling.LANCZOS);im.paste(pic,(x+(406-pic.width)//2,112+(255-pic.height)//2))
  pic=P.open(src,reference=True).crop((0,430,870,1050)).convert('RGB');pic=ImageOps.contain(pic,(406,210),Image.Resampling.LANCZOS);im.paste(pic,(x+(406-pic.width)//2,375+(210-pic.height)//2))
 else:
  tile(im,src,(x,112,x+406,367))
  tile(im,T/'chorus_C10'/('before' if i==1 else 'after')/'maw_close.png',(x,375,x+406,585),crop=(180,100,1110,670))
ImageDraw.Draw(im).text((650,632),'Two forward slots | tendrils and insides preserved',font=font(19),fill=FG)
save(im,'C10_concept_before_after.jpg')
# The rejected run 1 rims need their own close comparison with the concept.
im=canvas('C10 | run 2 | folded flesh lips','R306 | concept, run 1 8e9def50 and v7 | CPU sheet built, unpainted')
for i,(text,state) in enumerate((('CONCEPT | accepted R204',None),('RUN 1 | ring rims','run1'),('AFTER | v7 folded lips','after'))):
 x=16+i*422;label(im,(x,92),text)
 if state is None:
  pic=P.open(concept,reference=True).crop((60,530,700,1030)).convert('RGB')
  pic=ImageOps.contain(pic,(406,430),Image.Resampling.LANCZOS)
  im.paste(pic,(x+(406-pic.width)//2,145+(430-pic.height)//2))
 else:
  tile(im,T/'chorus_C10'/state/'maw_close.png',(x,145,x+406,575),crop=(180,100,1110,670))
ImageDraw.Draw(im).text((650,636),'Different hoods and side folds on each maw.',font=font(18),fill=FG)
save(im,'C10_rims_run2.jpg')
# Exposing before/after views, with fixed crops and the same camera in both columns.
for view,name,title in (('maw_close','C10_maws.jpg','open maws'),('flesh_close','C10_flesh.jpg','flesh relief')):
 im=canvas('C10 | v7 | '+title,'Before: main 51ec81bb | After: working v7 | sheet built, unpainted | CPU / matched camera and light')
 for i,state in enumerate(('before','after')):
  x=16+i*632;label(im,(x,85),state.upper())
  tile(im,T/'chorus_C10'/state/(view+'.png'),(x,119,x+616,590),crop=(180,100,1110,670) if view=='maw_close' else None)
 if view=='maw_close':
  ImageDraw.Draw(im).text((650,628),'Open throats and deep glow are kept from run 1',font=font(18),fill=FG)
  ImageDraw.Draw(im).text((650,656),'Unequal overlapping hoods, cheeks and lower folds',font=font(18),fill=FG)
 else:
  ImageDraw.Draw(im).text((650,632),'Wrinkles, gathered folds and sunk regrowth seams',font=font(19),fill=FG)
 save(im,name)
im=canvas('C10 | camera 170 | before and after','CPU sheet projection, unpainted | 1280x720 native pixels | game elevation, 45 deg vertical FOV, class scale 1.6')
for i,state in enumerate(('before','after')):
 x=16+i*632;label(im,(x,85),state.upper()+' | '+('main 51ec81bb' if state=='before' else 'v7 working'))
 pic=P.open(T/'chorus_C10'/state/'cam170.png').convert('RGB').crop((330,85,950,595))
 im.paste(pic,(x,112))
ImageDraw.Draw(im).text((650,651),'Centre crops only; the ship pixels are not enlarged.',font=font(18),fill=FG)
save(im,'C10_camera170.jpg')
# A compact sheet keeps true views at one scale instead of a tall stacked page.
im=canvas('C10 | Ninefold Maw | build sheet v7','Bio-titan | game length 28.0 | sheet built, unpainted | CPU | full data in feature_table.md')
for name,y in (('side',98),('top',264),('underside',430)):
 label(im,(18,y-12),'TRUE '+name.upper())
 tile(im,R/(name+'.png'),(18,y+12,766,y+154),rotate=name in ('top','underside'))
for name,box in (('bow',(820,115,1240,265)),('stern',(820,288,1240,438)),('cutaway',(800,475,1250,590))):
 label(im,(box[0],box[1]-24),name.upper());tile(im,R/(name+'.png'),box)
save(im,'sheet.jpg')
# A readable preview leads with the requested correction.
P.copy(D/'C10_concept_before_after.jpg',D/'preview.jpg')
P.copy(D/'C10_concept_before_after.jpg',D/'beauty_vs_blockout.jpg')
# Current slot table with the current concept-camera model.
wm=json.loads((R/'chorus_C10_weapon_match.json').read_text())
im=canvas('C10 | v7 | weapon match '+wm['result'],'Sheet built, unpainted | both maws remain fixed forward; crown and three spore glands retain their turns')
tile(im,T/'chorus_C10/after/concept.png',(0,80,1280,450))
for i,row in enumerate(wm['slots']):
 line='%d: %s %s | %d shots | %s'%(row['slot'],row['weapon'],row['arc'],row['shots'],', '.join('%s (%d muzzles)'%(m['id'],m['muzzles']) for m in row['mounts']))
 ImageDraw.Draw(im).text((650,472+38*i),line,font=font(18),fill=FG)
save(im,'weapon_review.jpg')
# Refresh structured outputs and make the bespoke route explicit on both sides.
for src,dst in ((R/'chorus_C10_fit.json','fit.json'),(R/'chorus_C10_weapon_match.json','weapon_match.json'),(L/'feature_table.md','feature_table.md'),(L/'fit_report.md','fit_report.md'),(L/'inventory.md','inventory.md'),(L/'cells.json','cells.json'),(L/'checks.json','checks.json')):
 shutil.copyfile(src,D/dst)
man=json.loads((L/'manifest.json').read_text())
for part in man['parts']:
 if part['id'] in ('M1','M2'):part['route']='hand-built';part['turret']=False;part.pop('pivot_object',None);part.pop('arc_lo',None);part.pop('arc_hi',None)
man['routes_note']+='; M1 and M2 use C10 hand-built open lips and funnels over the Chorus kit throat organs'
(D/'manifest.json').write_text(json.dumps(man,indent=1)+'\n')
ft=(D/'feature_table.md').read_text();lines=ft.splitlines();in_table=False
for i,line in enumerate(lines):
 if line.startswith('## Feature table'):in_table=True
 elif in_table and line.startswith('## '):in_table=False
 elif in_table and line.startswith('|'):
  cells=line.split('|')
  if cells[1].strip()=='ID':route='Route'
  elif set(cells[1].strip())<=set('-:'):route='---'
  else:route='hand-built' if cells[1].strip() in ('M1','M2') else 'kit'
  lines[i]=line+' '+route+' |'
ft='\n'.join(lines)+'\n'
ft=ft.replace('| outline iou percent | 76.4 |\n','').replace('| mass outline iou percent | 75.1 |\n','')
ft+='\n## Issue 921 surface ownership\n\nThe continuous wrinkled hide replaces the old pad layer. Broad folds, regrowth recesses and puckered scar lips are modelled here. Fine pore grain, mottling, wetness, scar colour and final maw emission await the Chorus stack. M1 and M2 are fixed, hand-built open maws assembled from the existing Chorus throat organs.\n'
(D/'feature_table.md').write_text(ft)
inv=(D/'inventory.md').read_text().replace('callused armour pads with sense pores','continuous folded hide with sense pores').replace('callus pads (irregular low domes), sense pores on them','continuous modelled wrinkle folds and the retained sense-pore fields')
inv=inv.replace('| hide | the hide: continuous folded hide with sense pores, the first thing a hit tears | plate |','| hide | the hide: continuous folded hide with sense pores, the first thing a hit tears | hull |')
inv+='\nIssue 921 / R306: this v7 output supersedes the old hide-pad description in the concept inventory. Large wrinkles and sunk scars are geometry. Only fine pore grain, wetness, mottling and scar colour wait for surfacing. Optional concept-sheet proportion analysis was not run because SciPy is absent; the real orthographic view agreement is in checks.json.\n'
(D/'inventory.md').write_text(inv)
# Silhouette at the unchanged concept camera, from the rendered alpha, not the old fitted score.
raw=P.open(R/'beauty_cam.png').convert('RGBA');ref=P.open(concept,reference=True).convert('RGB')
a=np.asarray(raw)[...,3]>8
c=np.asarray(ref.convert('L'))>25
# Keep the main concept organism, fill its holes, omit the small escort and stars.
mask=Image.fromarray((c*255).astype('uint8')).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
# Flood-fill scanlines for the largest connected component without an optional SciPy install.
arr=np.asarray(mask).copy();seen=np.zeros(arr.shape,bool);best=[]
for yy,xx in zip(*np.where(arr)):
 if seen[yy,xx]:continue
 stack=[(int(xx),int(yy))];runs=[];area=0
 while stack:
  x,y=stack.pop()
  if y<0 or y>=arr.shape[0] or x<0 or x>=arr.shape[1] or not arr[y,x] or seen[y,x]:continue
  l=x;r=x
  while l>0 and arr[y,l-1] and not seen[y,l-1]:l-=1
  while r+1<arr.shape[1] and arr[y,r+1] and not seen[y,r+1]:r+=1
  seen[y,l:r+1]=True;runs.append((y,l,r));area+=r-l+1
  for ny in (y-1,y+1):
   if 0<=ny<arr.shape[0]:
    open_run=False
    for nx in range(l,r+1):
     valid=bool(arr[ny,nx] and not seen[ny,nx])
     if valid and not open_run:stack.append((nx,ny))
     open_run=valid
 if area>sum(r-l+1 for y,l,r in best):best=runs
c=np.zeros(arr.shape,bool)
for y,l,r in best:c[y,l:r+1]=True
# Fill enclosed holes in the organism using Pillow's flood fill on the inverse.
from PIL import ImageDraw as ID
cm=Image.fromarray((c*255).astype('uint8'));pad=Image.new('L',(cm.width+2,cm.height+2),0);pad.paste(cm,(1,1));ID.floodfill(pad,(0,0),128);c=np.asarray(pad.crop((1,1,cm.width+1,cm.height+1)))!=128
score=float(np.logical_and(a,c).sum()/np.logical_or(a,c).sum())
refarr=np.asarray(ref).copy();refarr=(refarr*.65).astype('uint8')
for m,col in ((c,(40,210,235)),(a,(255,150,65))):
 edge=Image.fromarray((m*255).astype('uint8')).filter(ImageFilter.FIND_EDGES).filter(ImageFilter.MaxFilter(3));refarr[np.asarray(edge)>0]=col
im=canvas('C10 | v7 | outline at the concept camera','Cyan: accepted concept | orange: current model | overlap %.1f%%, reported without a pass bar'%(score*100))
pic=ImageOps.contain(Image.fromarray(refarr),(1280,510),Image.Resampling.LANCZOS);im.paste(pic,((1280-pic.width)//2,80))
save(im,'outline_check.jpg')
checks=json.loads((D/'checks.json').read_text());checks.pop('outline_iou_percent',None);checks.pop('mass_outline_iou_percent',None);checks['measured_outline_iou_percent']=round(score*100,2);checks['outline_method']='same fitted camera; render alpha vs main concept component, luminance >25, 5px closing, enclosed holes filled; reported, not gated'
(D/'checks.json').write_text(json.dumps(checks,indent=1)+'\n')
# Evidence and actual unbaked GLB budget.
before=json.loads((T/'chorus_C10/before/checks.json').read_text());run1=json.loads((T/'chorus_C10/run1/checks.json').read_text());after=json.loads((T/'chorus_C10/after/checks.json').read_text());contract=json.loads((T/'contract/sheet_contract_selftest.json').read_text());exp=json.loads((T/'export/B16_23_export.json').read_text());ec=json.loads((T/'export/B16_23_check.json').read_text());audit=json.loads((T/'audit.json').read_text());density=json.loads((T/'mesh_density.json').read_text())
glb=(T/'export/B16_23.glb').read_bytes();n=struct.unpack_from('<I',glb,12)[0];g=json.loads(glb[20:20+n]);surfaces=sum(len(m['primitives']) for m in g['meshes'])
proof=dict(issue=921,stage='sheet built, unpainted CPU proof',sheet_version=7,base_commit=after['source_revision'],design_sha256=after['source_sha256'],
 budget=dict(triangles=sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives']),surfaces=surfaces,estimated_draw_calls_per_single_pass=surfaces,materials=len(g['materials']),authored_inside_triangles=after['inside']['triangles'],scene_gate_measured=False),
 fit=after['fit'],weapon_match=wm['result'],contract=contract,audit=audit,export_check=dict(ok=ec['ok'],problems=ec['problems'],hardpoints=ec['hardpoints']),
 run1_commit=run1['source_revision'],
 preserved={k:run1[k]==after[k] for k in ('inside','inside_rows','tendril','unmodified_outline_parts')},
 geometry_fingerprints={k:after[k] for k in ('inside','tendril','unmodified_outline_parts')},
 maw_read=dict(main=before['maw_read'],run1=run1['maw_read'],after=after['maw_read'],note='Axial rays through a 2-unit diameter circle at each actual mouth; depth starts at the foremost lip. These are measurements, not arbitrary gates.'),
 outline=checks['measured_outline_iou_percent'],mesh_density=density,limits=['No Chorus paint stack, game install or GPU frame-time measurement in this sheet-only job.','Optional inventory concept-sheet proportions omitted because SciPy is absent; per-cell inventory checks pass and orthographic agreement was measured.'])
rim_names={'M1_body_flesh','M2_body_flesh','M1_body_flesh2','M2_body_flesh2'}
run1_kept={k:v for k,v in run1['preserved_objects'].items() if k not in rim_names}
after_kept={k:v for k,v in after['preserved_objects'].items() if k not in rim_names}
proof['preserved']['every_non_rim_mesh']=run1_kept==after_kept
proof['preserved_non_rim_meshes']=len(after_kept)
proof['rim_meshes']=dict(before={k:v for k,v in {**run1['preserved_objects'],**run1['lip_objects']}.items() if k in rim_names},after=after['lip_objects'])
proof['working_geometry_objects']=after['outside']['objects']
if not all(proof['preserved'].values()):
 raise RuntimeError('Run 2 changed anatomy outside the rims: '+str(proof['preserved']))
proof['inventory']=dict(failing=json.loads((D/'cells.json').read_text())['failing'],optional_concept_proportions='omitted: SciPy absent')
proof['orthographic_view_agreement']=checks
# Keep the real completed standing and manifest results when regenerating.
def read_log(name):
 data=(T/name).read_bytes()
 return data.decode('utf-16' if data.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig')
if (T/'standing.log').is_file():
 rows=[]
 for line in read_log('standing.log').splitlines():
  bits=line.split(' | ')
  if len(bits)>=4 and bits[1] in ('PASS','KNOWN','FAIL','SKIP'):
   rows.append(dict(check=bits[0],result=bits[1],seconds=float(bits[2]),detail=' | '.join(bits[3:])))
 if rows and not any(row['result'] in ('FAIL','SKIP') for row in rows):
  proof['standing_checks']=dict(command='node contrib/opus/tools/run_all_checks.js',exit_code=0,rows=rows)
if (T/'manifest.log').is_file() and 'PASS docs/ship_pipeline/build_sheets/chorus_C10' in read_log('manifest.log'):
 proof['manifest_check']=dict(command='node contrib/opus/tools/build_manifest_tests.js docs/ship_pipeline/build_sheets/chorus_C10',exit_code=0,result='PASS')
(D/'issue921_proof.json').write_text(json.dumps(proof,indent=2)+'\n')
(D/'density_seams.json').write_text(json.dumps(dict(note='Issue 921 v7, actual CPU build; mesh density reported without a new gate',seams=dict(machines=13,on_seam=audit['crossing_break_lines']),preserved_authored_insides=proof['preserved']['inside'],density=density),indent=2)+'\n')
print('Published C10 v7; overlap %.2f%%; %d triangles; %d surfaces/draws'%(score*100,proof['budget']['triangles'],surfaces))
print('Preserved',proof['preserved'])


