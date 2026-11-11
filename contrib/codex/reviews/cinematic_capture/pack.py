"""Make labelled evidence from real captures, without changing game pixels except crop/resize."""
import json, math, os, subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import imageio_ffmpeg

RAW = Path(os.environ['TEMP']) / 'cine487'
OUT = Path(__file__).resolve().parents[4] / 'docs/shots/cinematic_audit'
OUT.mkdir(parents=True, exist_ok=True)
FONT = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 18)
SMALL = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 15)

def text(draw, xy, s, font=FONT):
    draw.text(xy, s, font=font, fill='white', stroke_width=2, stroke_fill='black')

def strip(name, title, frames, boxes=None, labels=None, routes=None):
    sheet = Image.new('RGB', (1280, 720), '#10151c')
    draw = ImageDraw.Draw(sheet)
    text(draw, (12, 8), title)
    for i, f in enumerate(frames):
        img = Image.open(f)
        if boxes: img = img.crop(boxes[i])
        img.thumbnail((420, 300))
        x, y = (i % 3) * 426, 42 + (i // 3) * 334
        sheet.paste(img, (x, y))
        text(draw, (x+7, y+303), labels[i] if labels else Path(f).stem, SMALL)
    sheet.save(OUT / name, quality=92)

def encode(tag):
    folder = RAW / tag
    files = sorted(folder.glob('*.jpg'))
    # Source files are every sixth simulation frame, captured at 60 Hz.
    listing = folder / 'video_list.txt'
    listing.write_text(''.join("file '%s'\nduration 0.1\n" % str(f).replace('\\','/') for f in files), encoding='utf-8')
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-y', '-v', 'error', '-f', 'concat', '-safe', '0', '-i', str(listing), '-vf', 'scale=1280:-2', '-c:v', 'libx264', '-crf', '22', '-pix_fmt', 'yuv420p', str(RAW / (tag+'.mp4'))], check=True)

def battle_frames(tag, times):
    folder=RAW/tag
    data=json.loads((folder/'telemetry.json').read_text())
    available=[int(f.stem) for f in folder.glob('*.jpg')]
    frames=[]; labels=[]
    for t in times:
        row=min(data['samples'],key=lambda r:abs(r['t']-t))
        n=min(available,key=lambda n:abs(n-row['frame']))
        frames.append(folder/('%06d.jpg'%n))
        actual=data['samples'][n]
        labels.append('t %.2f s, round %s'%(actual['t'],actual['round']))
    return frames,labels

def motion():
    measures=[]; index=1
    for kind in ['straight','turn','final','obstacle']:
        folder=RAW/('motion_'+kind)
        if not (folder/'motion.json').exists(): continue
        for row in json.loads((folder/'motion.json').read_text()):
            if 'unavailable' in row:
                measures.append(row); continue
            ts=row['telemetry']; cls=row['cls']
            last_moving=max((p['t'] for p in ts if p['moving']),default=ts[-1]['t'])
            ts=[p for p in ts if p['t']<=last_moving+0.15]
            available=sorted(f for f in (folder/cls).glob('*.jpg') if int(f.stem)<len(ts) and f.stat().st_size)
            if not available: continue
            picks=[min(range(len(ts)),key=lambda n:abs(ts[n]['t']-ts[-1]['t']*i/5)) for i in range(6)]
            frames=[min(available,key=lambda f:abs(int(f.stem)-n)) for n in picks]
            points=[p['screen'] for p in ts]
            cx=(min(p[0] for p in points)+max(p[0] for p in points))/2
            cy=(min(p[1] for p in points)+max(p[1] for p in points))/2
            w=max(630,max(p[0] for p in points)-min(p[0] for p in points)+240)
            h=max(450,max(p[1] for p in points)-min(p[1] for p in points)+180)
            w=max(w,h*1.4); h=w/1.4
            box=(cx-w/2,cy-h/2,cx+w/2,cy+h/2)
            name='m%02d_%s_%s.jpg'%(index,cls.lower(),kind)
            labels=['t %.2f s | drive %.2f'%(ts[int(f.stem)]['t'],ts[int(f.stem)]['thrust']) for f in frames]
            strip(name, '%s: %s, camera 170 | six evenly spaced times'%(cls,kind), frames,[box]*6,labels)
            velocities=[]; turns=[]
            for a,b in zip(ts,ts[1:]):
                dt=b['t']-a['t']
                velocities.append((b['t'],math.dist(a['p'],b['p'])/dt,math.dist(a['screen'],b['screen'])/dt))
                dy=(b['rot'][1]-a['rot'][1]+math.pi)%(2*math.pi)-math.pi
                turns.append(abs(math.degrees(dy)/dt))
            peak=max(v[1] for v in velocities)
            full=next((v[0] for v in velocities if v[1]>=peak*.95),None)
            lastfull=max((v[0] for v in velocities if v[1]>=peak*.95),default=0)
            stop=next((v[0] for v in velocities if v[0]>lastfull and v[1]<=peak*.05),ts[-1]['t'])
            measures.append({'picture':name,'class':cls,'kind':kind,'duration_s':ts[-1]['t'],'to_95pct_peak_s':full,'95_to_5pct_stop_s':stop-lastfull,'peak_world_units_s':peak,'peak_pixels_s':max(v[2] for v in velocities),'peak_yaw_deg_s':max(turns),'max_roll_deg':max(abs(math.degrees(p['rot'][0])) for p in ts),'path':row['path'],'score':row['score']})
            index+=1
    (OUT/'movement_measurements.json').write_text(json.dumps(measures,indent=2))
    return measures

if __name__=='__main__':
    import sys
    if sys.argv[1]=='video': encode(sys.argv[2])
    elif sys.argv[1]=='motion': print(json.dumps(motion(),indent=2))
