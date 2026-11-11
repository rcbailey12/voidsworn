from pack import *
from collections import Counter

def wide():
    d=json.loads((RAW/'large/telemetry.json').read_text())
    ids=[s['id'] for s in d['samples'][0]['ships'][:10]]
    fs,labels=battle_frames('large',[0,18,36,54,72,90])
    for i,(f,t) in enumerate(zip(fs,[0,18,36,54,72,90])):
        im=Image.open(f); dr=ImageDraw.Draw(im)
        for sid in ids:
            pts=[tuple(s['screen']) for r in d['samples'][::6] if r['t']<=t for s in r['ships'] if s['id']==sid]
            if len(pts)>1: dr.line(pts,fill='#ffff66',width=5)
        dest=RAW/('wide_%d.jpg'%i);im.save(dest);fs[i]=dest
    strip('m13_whole_side.jpg','Twenty-ship battle: one full side moves | yellow = observed tracks, camera 240',fs,labels=labels)

def audio():
    d=json.loads((RAW/'small/telemetry.json').read_text())
    cue_times=[x['t'] for x in d['cues'] if x['cue']=='ui_round']
    counts=[]
    for i,t in enumerate(cue_times):
        end=cue_times[i+1] if i+1<len(cue_times) else float('inf')
        c=Counter(x['cue'] for x in d['cues'] if t<=x['t']<end)
        counts.append({'round':i+1,'starts':sum(c.values()),'distinct_cues':len(c),'counts':dict(c)})
    (OUT/'audio_counts.json').write_text(json.dumps(counts,indent=2))
    fs,labels=battle_frames('small',[32.0,32.1,32.2,32.3,32.4,32.5])
    strip('f03_generic_hit_audio.jpg','Different weapon hits share hit / hit_heavy | log evidence, not a listening verdict',fs,[(1800,900,2950,1650)]*6,labels)
    im=Image.open(OUT/'f03_generic_hit_audio.jpg'); dr=ImageDraw.Draw(im)
    dr.rectangle((8,646,1270,716),fill='#10151c')
    text(dr,(18,651),'Small fight: 40 hit, 5 hit_heavy; 18 gun_las, 17 gun_plasma, 9 lance_ion',SMALL)
    text(dr,(18,676),'hit offers six hullHit + four hullTick samples. Exact selected clip paths were not logged in this run.',SMALL)
    im.save(OUT/'f03_generic_hit_audio.jpg',quality=92)

if __name__=='__main__':
    wide(); audio()
    fs,labels=battle_frames('small',[54.5,54.8,55.1,55.5,56.1,57])
    strip('b04_small_death.jpg','Small-ship death: lead-in and wreck, supplied as evidence without a new break finding',fs,[(2400,850,3100,1350)]*6,labels)
    fs,labels=battle_frames('small',[16.6,16.7,16.8,16.9,17,17.1])
    strip('f02_salvo.jpg','Las exchange: short repeated strokes at the battle camera',fs,[(1800,800,2950,1550)]*6,labels)
    bench=json.loads((RAW/'bench/bench.json').read_text())
    sheet=Image.new('RGB',(1280,720),'#10151c'); draw=ImageDraw.Draw(sheet)
    text(draw,(12,8),'Same battleship battery, three targets | camera 170, native 384 x 216 crops')
    for col,(rid,label) in enumerate([('k_macro_frigate','Frigate: flash setting 44.8 px'),('k_macro_cruiser','Cruiser: flash setting 56 px'),('k_macro_tombark','Tomb-ark: flash setting 67.2 px')]):
        row=next(r for r in bench['stills'] if r.get('id')==rid and r.get('cam')==170)
        img=Image.open(RAW/'bench'/row['file'])
        for j,k in enumerate([2,5]):
            x=col*426+20;y=80+j*300
            cell=img.crop((k*384,0,(k+1)*384,216))
            sheet.paste(cell,(x,y))
            text(draw,(x,y+225),'t %.3f s | %s'%(row['cells'][k]['t'],label),SMALL)
    sheet.save(OUT/'f01_heavy_hits.jpg',quality=92)
    for n,sky in enumerate(['world','frontier','storm'],1):
        sheet=Image.new('RGB',(1280,720),'#10151c');draw=ImageDraw.Draw(sheet)
        text(draw,(12,8),'Fleet scene f%d: %s | 36 real hulls at camera 170 (reduced for this overview)'%(n,sky))
        for i,f in enumerate(sorted((RAW/'bench/fleet'/sky).glob('*.png'))):
            cell=Image.open(f);cell.thumbnail((210,94));x=(i%6)*213;y=40+(i//6)*112
            sheet.paste(cell,(x,y));text(draw,(x+2,y+94),f.stem,SMALL)
        sheet.save(OUT/('b%02d_fleet_%s.jpg'%(n,sky)),quality=90)
