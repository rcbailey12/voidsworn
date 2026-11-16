"""R271 real-pixel sheets, complete regression sweep, and phone flight film.

python round3_sheets.py --before DIR --after DIR --out DIR
No effect pixels are repainted. Source-pixel crops and full-frame 390 px
phone reductions are labelled separately. All sheets are at most 1280x720.
"""
import argparse
import json
import math
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw
import numpy as np
from make_sheets import font, frame, TIMES
from round2_sheets import load, phone


def difference_stats(before,after):
    assert before.size==after.size
    delta=ImageChops.difference(before,after)
    hist=delta.histogram()
    rms=math.sqrt(sum(sum(v*v*count for v,count in enumerate(hist[k*256:(k+1)*256])) for k in range(3))/(before.width*before.height*3))
    return dict(rms=rms,different_above_1=sum(sum(hist[k*256+2:(k+1)*256]) for k in range(3)),
        max_delta=max(hi for lo,hi in delta.getextrema()))


def comparison(name, before, after, bm, am, time, out):
    sheet = Image.new('RGB', (1280,720), '#0b1019')
    d = ImageDraw.Draw(sheet)
    d.text((10,6),f'KIT 815 / {name} / c170 + PHONE + c60',font=font(20),fill='#efd7a6')
    for i,(run,rows,label) in enumerate([(before,bm,'ROUND 2'),(after,am,'ROUND 3')]):
        y=38+i*346
        im,actual=frame(run,rows[name,170],time)
        sheet.paste(im.crop((0,30,640,330)),(0,y+26))
        d.text((8,y),f'{label} / c170 source pixels / t={actual:.3f}s',font=font(16),fill='#cbd9e8')
        sheet.paste(phone(run,rows[name,170],time),(650,y+65))
        d.text((650,y+31),'Full frame / phone width 390 px',font=font(15),fill='#cbd9e8')
        im,_=frame(run,rows[name,60],time,native=True)
        x0=0 if name=='gauss' else 200
        sheet.paste(im.crop((x0,30,x0+240,330)),(1040,y+26))
        scale='c60 source pixels' if 'native_file' in rows[name,60] else 'c60 / scale 1:3'
        d.text((1044,y),scale,font=font(15),fill='#cbd9e8')
    sheet.save(out/f'{name}.png')


def film(name, run, row, out):
    fire=row.get('fires',[.25])[0]
    times=[c['t'] for c in row['cells'] if (fire-1e-4 if name=='gauss' else .30)<=c['t']<=1.40]
    images=[]
    phone_images=[]
    phone_frames={}
    source_strip=Image.open(run/row['file']).convert('RGB')
    phone_strip=Image.open(run/row['phone_file']).convert('RGB')
    cells=row['cells']
    for time in times:
        canvas=Image.new('RGB',(1040,360),'#0b1019')
        d=ImageDraw.Draw(canvas)
        index=min(range(len(cells)),key=lambda i:abs(cells[i]['t']-time))
        actual=cells[index]['t']
        im=source_strip.crop((index*640,0,(index+1)*640,360))
        ph=phone_strip.crop((index*390,0,(index+1)*390,219))
        phone_frames[time]=ph
        canvas.paste(im.crop((0,30,640,330)),(0,40))
        canvas.paste(ph,(650,75))
        d.text((8,7),f'KIT 815 / {name} / c170 / t={actual:.3f}s',font=font(19),fill='#efd7a6')
        d.text((650,40),'Full frame / phone 390 px',font=font(16),fill='#cbd9e8')
        images.append(canvas)
        phone_canvas=Image.new('RGB',(390,249),'#0b1019')
        phone_canvas.paste(ph,(0,30))
        ImageDraw.Draw(phone_canvas).text((8,5),f'KIT 815 / {name} / t={actual:.3f}s',font=font(17),fill='#efd7a6')
        phone_images.append(phone_canvas)
    # Error diffusion at 256 colours preserves the dark sky and bright tracer.
    # GIF uses 10 ms ticks. Quantise the accumulated clock, preserving 60 Hz
    # as 20/10/20 ms and 30 Hz as 30/40/30 ms instead of speeding up the film.
    ticks=[round((t-times[0])*100) for t in times]
    ticks.append(round((times[-1]-times[0]+times[-1]-times[-2])*100))
    duration=[max(10,(ticks[i+1]-ticks[i])*10) for i in range(len(times))]
    images[0].save(out/f'{name}_motion.gif',save_all=True,append_images=images[1:],duration=duration,loop=0)
    phone_images[0].save(out/f'{name}_phone_motion.gif',save_all=True,append_images=phone_images[1:],duration=duration,loop=0)
    if name=='doom':
        sheet=Image.new('RGB',(1280,720),'#0b1019')
        d=ImageDraw.Draw(sheet)
        d.text((10,5),'KIT 815 / doom / c170 SOURCE PIXELS / FLOW AND COOLING',font=font(20),fill='#efd7a6')
        for j,time in enumerate([.40,.60,.80,1.20]):
            index=min(range(len(cells)),key=lambda i:abs(cells[i]['t']-time))
            im=source_strip.crop((index*640,30,(index+1)*640,330))
            x,y=(j%2)*640,38+(j//2)*340
            d.text((x+8,y),f'ROUND 3 / t={cells[index]["t"]:.3f}s',font=font(17),fill='#cbd9e8')
            sheet.paste(im,(x,y+25))
        sheet.save(out/'doom_sequence.png')
    if name=='gauss':
        # Every 60 Hz frame during the real flight, including muzzle and contact.
        impact=row['impacts'][0]
        samples=[c['t'] for c in row['cells'] if fire-1e-4<=c['t']<=impact+1/60]
        for page,start in enumerate(range(0,len(samples),6)):
            count=min(6,len(samples)-start)
            sheet=Image.new('RGB',(1280,40+250*math.ceil(count/3)),'#0b1019')
            d=ImageDraw.Draw(sheet)
            d.text((10,5),f'KIT 815 / gauss / PHONE FLIGHT FRAMES {start+1}-{start+count} / width 390 px',font=font(20),fill='#efd7a6')
            for j,time in enumerate(samples[start:start+6]):
                x,y=(j%3)*420,34+(j//3)*250
                d.text((x+8,y),f't={time:.4f}s',font=font(17),fill='#cbd9e8')
                sheet.paste(phone_frames[time],(x+8,y+24))
            sheet.save(out/f'gauss_phone_flight_{page+1}.png')


def regression_review(before,after,bm,am,sweep,detail_phone,out):
    intended={'doom','gauss','gflak','p_gauss_exit','p_torp_shield'}
    intended|={name for name,cam in am if name.startswith('shield_')}
    candidates=[r for r in sweep+detail_phone if r['different_above_1'] and r['id'] not in intended]
    names=sorted({r['id'] for r in candidates},
        key=lambda name:max(r['rms'] for r in candidates if r['id']==name),reverse=True)
    review=[]
    pages=[]
    for i,name in enumerate(names):
        metric=max((r for r in candidates if r['id']==name),key=lambda r:r['rms'])
        camera=metric['camera']
        b,n=bm[name,camera],am[name,camera]
        field=metric.get('view','file')
        bi=Image.open(before/b[field]).convert('RGB')
        ni=Image.open(after/n[field]).convert('RGB')
        cw=bi.width//len(b['cells'])
        diff=np.asarray(ImageChops.difference(bi,ni)).max(axis=2)
        yy,xx=np.unravel_index(diff.argmax(),diff.shape)
        index=int(xx)//cw
        x,y=int(xx)%cw,int(yy)
        cropx=max(0,min(cw-200,x-100)); cropy=max(0,min(bi.height-200,y-100))
        bf=bi.crop((index*cw,0,(index+1)*cw,bi.height))
        nf=ni.crop((index*cw,0,(index+1)*cw,ni.height))
        if i%6==0:
            page=Image.new('RGB',(1280,720),'#0b1019')
            ImageDraw.Draw(page).text((10,5),'KIT 815 / UNCHANGED ROWS / PEAK DIFFERENCE REVIEW',font=font(20),fill='#efd7a6')
            pages.append(page)
        px,py=(i%3)*426,42+((i%6)//3)*334
        d=ImageDraw.Draw(page)
        d.text((px+7,py),f'{name} / c{camera} / t={n["cells"][index]["t"]:.3f}',font=font(16),fill='#cbd9e8')
        for j,im in enumerate([bf,nf]):
            page.paste(im.crop((cropx,cropy,cropx+200,cropy+200)),(px+7+j*207,py+47))
            d.text((px+7+j*207,py+25),'ROUND 2' if j==0 else 'ROUND 3',font=font(15),fill='#cbd9e8')
        d.text((px+7,py+255),f'RMS {metric["rms"]:.4f}/255; max {metric["max_delta"]}',font=font(15),fill='#cbd9e8')
        review.append(dict(metric,frame=index,time=n['cells'][index]['t'],crop=[cropx,cropy,200,200]))
        if i<2:
            full=Image.new('RGB',(cw*2,bi.height+38),'#0b1019')
            ImageDraw.Draw(full).text((10,5),f'KIT 815 / {name} / unchanged / peak frame / c{camera} / BEFORE LEFT, AFTER RIGHT',font=font(18),fill='#efd7a6')
            full.paste(bf,(0,38)); full.paste(nf,(cw,38))
            full.save(out/f'regression_full_{name}.png')
    for i,page in enumerate(pages):
        page.save(out/f'regression_review_{i+1}.png')
    (out/'regression_review.json').write_text(json.dumps(review,indent=1))


def main():
    p=argparse.ArgumentParser()
    for key in ['before','after','out']:
        p.add_argument('--'+key,type=Path,required=True)
    p.add_argument('--before-contact',type=Path)
    p.add_argument('--after-contact',type=Path)
    a=p.parse_args()
    a.out.mkdir(parents=True,exist_ok=True)
    bm,am=load(a.before),load(a.after)
    assert set(bm)==set(am)
    sweep=[]
    detail_phone=[]
    for key in sorted(am):
        b,n=bm[key],am[key]
        bi=Image.open(a.before/b['file']).convert('RGB')
        ni=Image.open(a.after/n['file']).convert('RGB')
        assert bi.size==ni.size and [c['t'] for c in b['cells']]==[c['t'] for c in n['cells']]
        assert b['capture_batch']==n['capture_batch']
        sweep.append(dict(id=key[0],camera=key[1],**difference_stats(bi,ni)))
        for field in ['native_file','phone_file']:
            assert (field in b)==(field in n),(key,field)
            if field in b:
                bd=Image.open(a.before/b[field]).convert('RGB')
                nd=Image.open(a.after/n[field]).convert('RGB')
                detail_phone.append(dict(id=key[0],camera=key[1],view=field,**difference_stats(bd,nd)))
    for name in sorted({k[0] for k in am}):
        row=am[name,170]
        if name.startswith('shield_') or name=='p_torp_shield':
            time=row['impacts'][0]+.20
        else:
            time=TIMES.get(name,row['cells'][min(4,len(row['cells'])-1)]['t'])
        if name=='gauss':
            time=(row.get('fires',[.25])[0]+row['impacts'][0])*.5
        comparison(name,a.before,a.after,bm,am,time,a.out)
    for name in ['doom','gauss']:
        film(name,a.after,am[name,170],a.out)
    regression_review(a.before,a.after,bm,am,sweep,detail_phone,a.out)
    if a.before_contact and a.after_contact:
        bmc,amc=load(a.before_contact),load(a.after_contact)
        comparison('doom_contact',a.before_contact,a.after_contact,bmc,amc,.60,a.out)
        sheet=Image.new('RGB',(1280,720),'#0b1019')
        d=ImageDraw.Draw(sheet)
        d.text((10,5),'KIT 815 / doom_contact / c60 SOURCE PIXELS / PLATING COOLS TO SCORCH',font=font(19),fill='#efd7a6')
        for j,time in enumerate([.60,1.10,2.0,3.5]):
            x,y=(j%2)*640,38+(j//2)*340
            im,actual=frame(a.after_contact,amc['doom_contact',60],time,native=True)
            d.text((x+8,y),f'ROUND 3 / t={actual:.3f}s',font=font(17),fill='#cbd9e8')
            sheet.paste(im.crop((0,30,640,330)),(x,y+25))
        sheet.save(a.out/'doom_cooling.png')
    (a.out/'whole_kit_pixels.json').write_text(json.dumps(sweep,indent=1))
    (a.out/'detail_phone_pixels.json').write_text(json.dumps(detail_phone,indent=1))
    for path in a.out.iterdir():
        if path.suffix.lower() in ['.png','.gif']:
            with Image.open(path) as im:
                assert im.width<=1280 and im.height<=720,path
    print('ROUND3_SHEETS_DONE',len(am)//2,'rows')


if __name__=='__main__':
    main()
