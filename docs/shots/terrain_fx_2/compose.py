"""Compose the issue 100 review sheets from stamped Godot captures."""
import argparse,sys
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
p=argparse.ArgumentParser();p.add_argument('--repo',required=True);p.add_argument('--shots',required=True);p.add_argument('--out',required=True);a=p.parse_args()
repo=Path(a.repo);shots=Path(a.shots);out=Path(a.out);out.mkdir(parents=True,exist_ok=True)
sys.path.insert(0,str(repo/'tools'))
from picture_provenance import Review
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',19)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',16)

def panel(sheet,im,x,y,w,h,crop=None):
 if crop: im=im.crop(crop)
 im=im.resize((w,h),Image.Resampling.LANCZOS)
 sheet.paste(im,(x,y))

def after(name):
 return shots/"after_verified"/name

for case in ['graveyard','station','planet','deadstar']:
 review=Review('installed in game');sheet=Image.new('RGB',(1280,720),'#10151e');d=ImageDraw.Draw(sheet)
 for col,tag in enumerate(['before','after']):
  x=col*640; file=case+'_cine_c170.jpg';path=shots/'before'/file if tag=='before' else after(file)
  full=review.open(path);panel(sheet,full,x,32,640,360)
  d.text((x+10,6),case+' | '+tag+' | cine c170',font=font,fill='#f1e8d9')
  if case=='deadstar':
   detail=full;crop=(2400,750,3680,1110);label='Well rim: crop of the default camera'
  else:
   file=case+'_cine_c60.jpg';path=shots/'before'/file if tag=='before' else after(file)
   detail=review.open(path);crop=(600,700,3240,1440);label='Detail inset: same scene at c60'
  panel(sheet,detail,x,416,640,180,crop)
  d.text((x+10,395),label,font=small,fill='#dcc7a8')
 review.save(sheet,out/(case+'.jpg'),quality=95)

for case in ['storm','belt']:
 review=Review('installed in game');sheet=Image.new('RGB',(1280,720),'#10151e');d=ImageDraw.Draw(sheet)
 for row,look in enumerate(['today','holo']):
  for col,tag in enumerate(['before','after']):
   x=col*640;y=row*296;file=case+'_'+look+'_c170.jpg';path=shots/'before'/file if tag=='before' else after(file)
   im=review.open(path);panel(sheet,im,x,y+26,640,270,(0,270,3840,1890))
   d.text((x+10,y+3),case+' | '+look+' | '+tag+' | c170',font=font,fill='#f1e8d9')
 review.save(sheet,out/(case+'_old_looks.jpg'),quality=95)

for case in ['graveyard','deadstar']:
 review=Review('installed in game');sheet=Image.new('RGB',(1280,720),'#10151e');d=ImageDraw.Draw(sheet)
 for col,tier in enumerate(['max','low']):
  file=case+('_low' if tier=='low' else '')+'_cine_c170.jpg';path=after(file)
  full=review.open(path);x=col*640;panel(sheet,full,x,40,640,360)
  d.text((x+10,8),case+' | '+tier+' | cine c170',font=font,fill='#f1e8d9')
  panel(sheet,full,x,428,640,180,(1100,700,2740,1160))
  d.text((x+10,405),'Detail crop of this c170 frame',font=small,fill='#dcc7a8')
 review.save(sheet,out/(case+'_quality.jpg'),quality=95)

review=Review('installed in game');sheet=Image.new('RGB',(1280,720),'#10151e');d=ImageDraw.Draw(sheet)
for col,variant in enumerate(['on','off']):
 im=review.open(shots/'after_verified'/('well_guard_'+variant+'.jpg'))
 panel(sheet,im,col*640,40,640,360)
 panel(sheet,im,col*640,425,640,180,(1500,900,2340,1136))
 d.text((col*640+10,7),'deadstar | well '+variant+' | rim ship at c170',font=font,fill='#f1e8d9')
 d.text((col*640+10,404),'Hull detail crop: the well changes the background',font=small,fill='#dcc7a8')
review.save(sheet,out/'well_ship_guard.jpg',quality=95)
print('Composed nine stamped review sheets')
