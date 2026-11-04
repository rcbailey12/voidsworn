"""Assemble comparison sheets and 30 fps animated WebP recordings from probe frames.

ComfyUI Python evidence.py ISSUE_SHOTS
"""
import pathlib,sys
from PIL import Image,ImageDraw,ImageFont
out=pathlib.Path(sys.argv[1]); fontpath='C:/Windows/Fonts/segoeui.ttf'
font=lambda n:ImageFont.truetype(fontpath,n)
for cls in ['cruiser','battleship','frigate']:
    for zoom in ['battle','close']:
        name=cls+'_'+zoom
        before=out/'before'/name; after=out/'after'/name
        aa=sorted(before.glob('frame_*.jpg')); bb=sorted(after.glob('frame_*.jpg'))
        if len(aa)!=150 or len(bb)!=150: raise RuntimeError('Incomplete recording '+name)
        frames=[]
        for i,(a,b) in enumerate(zip(aa,bb)):
            im=Image.new('RGB',(1920,588),'#151320'); d=ImageDraw.Draw(im)
            d.text((20,8),cls.upper()+' / '+zoom.upper()+' / BEFORE',font=font(22),fill='#d7cbdc')
            d.text((980,8),'AFTER / '+f'{i/30:.2f} s',font=font(22),fill='#d7cbdc')
            im.paste(Image.open(a).resize((960,540)),(0,48));im.paste(Image.open(b).resize((960,540)),(960,48))
            frames.append(im)
        frames[0].save(out/(name+'.webp'),save_all=True,append_images=frames[1:],duration=[33,33,34]*50,loop=0,quality=78,method=3)
        print('RECORDING',name,flush=True)
        del frames
for zoom in ['battle','close']:
    sheet=Image.new('RGB',(1920,1330),'#151320');d=ImageDraw.Draw(sheet)
    d.text((24,12),'SPACE DEATHS / '+zoom.upper()+' / SAME HULLS, CAMERA AND EXPOSURE',font=font(30),fill='#e1d7c6')
    d.text((24,60),'Each row: before at 1.10 s / after vent at 0.43 s / after first cut at 1.10 s / after drift at 1.80 s',font=font(21),fill='#a99cb9')
    for row,cls in enumerate(['cruiser','battleship','frigate']):
        y=110+row*400
        d.text((24,y),cls.upper(),font=font(24),fill='#d7cbdc')
        specs=[('before',33,'BEFORE 1.10 s'),('after',13,'VENT 0.43 s'),('after',33,'BREAK 1.10 s'),('after',54,'DRIFT 1.80 s')]
        for col,(version,frame,label) in enumerate(specs):
            image=Image.open(out/version/(cls+'_'+zoom)/('frame_%03d.jpg'%frame)).resize((480,270))
            sheet.paste(image,(col*480,y+45));d.text((col*480+12,y+326),label,font=font(20),fill='#9d90ae')
    sheet.save(out/('comparison_'+zoom+'.png'))
html='<!doctype html><meta charset="utf-8"><title>Issue 137 death evidence</title><style>body{background:#151320;color:#dfd5e5;font:18px system-ui;margin:30px}img{width:100%;max-width:1920px}a{color:#bdd1ee}</style><h1>Space deaths, issue 137</h1><p>Same three Sunward Crusade hulls, camera positions and fixed exposure. Animated comparisons play at 30 fps. Left: before. Right: after.</p><img src="death_grammar.png">'
for cls in ['cruiser','battleship','frigate']:
    for zoom in ['battle','close']: html+='<h2>'+cls.title()+' / '+zoom+'</h2><img src="'+cls+'_'+zoom+'.webp">'
html+='<h2>4K profile</h2><p>20 real ships, 4x MSAA, Forward+, RTX 5080. No weapons or terrain. Readback is outside timing.</p><a href="profile/frame_times.json">Measured frame times</a><img src="profile/fleet_4k.png">'
html+='<h2>Quality tiers at 1.80 s</h2><p>Max has hot fracture rims. High has cold fracture faces. Low drops vent and spark emitters.</p>'
for tier in ['after','high','low']: html+='<h3>'+('Max' if tier=='after' else tier.title())+'</h3><img src="'+tier+'/cruiser_close/frame_054.jpg">'
(out/'index.html').write_text(html,encoding='utf-8')
