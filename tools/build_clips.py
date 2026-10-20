import subprocess, numpy as np, os, base64, json, tempfile
SR=48000
S='/mnt/user-data/uploads/Downloads/voidsworn_sfx/sonniss/'
K='k_scifi/Audio/'; KI='k_interface/Audio/'
def load(p):
    raw=subprocess.run(['ffmpeg','-v','quiet','-i',p,'-ac','1','-ar',str(SR),'-f','f32le','-'],capture_output=True).stdout
    return np.frombuffer(raw,dtype=np.float32).copy()
def trim_silence(x,thr=.003):
    idx=np.where(np.abs(x)>thr)[0]
    return x[idx[0]:idx[-1]+1] if len(idx) else x
def clip(p,a=0,b=None,fin=.003,fout=.25,peak=.89,trim=True):
    x=load(p); x=x[int(a*SR): (int(b*SR) if b else None)]
    if trim: x=trim_silence(x)
    n=len(x); fi=max(1,int(fin*SR)); fo=max(1,int(fout*n))
    x[:fi]*=np.linspace(0,1,fi); x[-fo:]*=np.linspace(1,0,fo)**2
    x*=peak/max(1e-6,np.abs(x).max()); return x
def loop(p,a,L,F=1.5,peak=.6):
    x=load(p); s=x[int(a*SR):int((a+L+F)*SR)]; L_=int(L*SR); F_=int(F*SR)
    out=s[:L_].copy(); t=np.linspace(0,1,F_); out[:F_]=out[:F_]*np.sqrt(t)+s[L_:L_+F_]*np.sqrt(1-t)
    out*=peak/np.abs(out).max(); return out
def enc(x,kbps=40):
    with tempfile.NamedTemporaryFile(suffix='.f32') as f, tempfile.NamedTemporaryFile(suffix='.ogg') as o:
        f.write(x.astype(np.float32).tobytes()); f.flush()
        subprocess.run(['ffmpeg','-v','quiet','-y','-f','f32le','-ar',str(SR),'-ac','1','-i',f.name,'-c:a','libopus','-b:a',f'{kbps}k','-vbr','on','-application','audio',o.name],check=True)
        return open(o.name,'rb').read()
P={
 'boomBig':[clip(S+'Federico Soler - Effective Trailer Booms Vol. 2/EffectiveTrailer_Booms_Vol2_011.wav',.2,4.6,fout=.45),
            clip(S+'Federico Soler - Effective Trailer Booms Vol. 2/EffectiveTrailer_Booms_Vol2_075.wav',.2,4.2,fout=.45),
            clip(S+'Federico Soler - Effective Trailer Booms Vol. 2/EffectiveTrailer_Booms_Vol2_214.wav',.2,4.6,fout=.45)],
 'boomSmall':[clip(S+'Epic Stock Media - Anime Game/EXPLDsgn_Explosion Small Blast Enemy Death Crunchy Boom Cartoon Noisy Crash Impact Delay 03_ESM_AG.wav',0,1.1)]+[clip(K+f'explosionCrunch_00{i}.ogg') for i in (1,3,4)],
 'boomLow':[clip(K+f'lowFrequency_explosion_00{i}.ogg') for i in (0,1)],
 'debris':[clip(S+'Cinematic Sound Design - Colossal Impacts/Woosh Debris.wav',.1,1.5,fout=.4),
           clip(S+'Ivo Vicic - Fireworks FX/13 Fireworks_powerful explosions_multiples in a row_near.wav',2.6,4.0,fout=.4)],
 'bassDrop':[clip(S+'344 Audio - Bass Drops & Downers Vol. 1/DSGNBass_Bass Drop & Downer Fast 16_344 Audio_Bass Drops & Downers.wav',0,2.0)],
 'hullHit':[clip(S+'Epic Stock Media - HD Game Materials/METLImpt_Metal Old File Impact Tap Against Tire Iron Metallic Hit 01_ESM_HDGM.wav',.1,.45)]+[clip(K+f'impactMetal_00{i}.ogg') for i in range(5)],
 'hullHitBig':[clip(S+'The Noisery - Moaning Metal/DSGNImpt_Metal Hit Thud Thump Low Ring Geofon 1_The Noisery_Moaning Metal.wav',0,2.2,fout=.5),
               clip(S+'David Dumais Audio - Melee Weapons Sound Effects Pack 2/METLImpt_METAL SWING HIT Weapon Swing To Metallic Body Impact And Resonant Tail 01_DDUMAIS_MWP2.wav',0,1.8,fout=.5)],
 'shieldHit':[clip(K+f'forceField_00{i}.ogg') for i in range(5)],
 'shieldBig':[clip(S+'Epic Stock Media - Elemental Mutation Whooshes and Impacts/ELECMisc_Impact Electric Tonal Deep Movement Motion Hiss Glitch 01_ESM_EMWI.wav',0,1.4,fout=.5)],
 'laserLarge':[clip(K+f'laserLarge_00{i}.ogg') for i in range(5)],
 'laserSmall':[clip(K+f'laserSmall_00{i}.ogg') for i in range(5)],
 'arc':[clip(S+'InMotionAudio - Arc/ELECArc_ArcDesign15_InMotionAudio_Arc.wav',0,.9)],
 'ionCharge':[clip(S+'InMotionAudio - Arc/ELECArc_ArcPowerUpDesign04_InMotionAudio_Arc.wav',0,1.6,fout=.3)],
 'whoosh':[clip(S+'344 Audio - Elemental Palette Designed Vol. 1/WINDDsgn_Wind, Rush, Whoosh, Long x5 01_344 Audio_Elemental Palette Designed Vol 1.wav')],
 'launch':[clip(S+'Epic Stock Media - Tower Defense Game/ROBTMvmt_Tower Deploy Hitech Robot Motor Dark Thump Servo Whine 04_ESM_TDG.wav',0,.8)],
 'scrape':[clip(S+'The Noisery - Moaning Metal/DSGNTonl_Metal Scrape Low Tonal LFE 4_The Noisery_Moaning Metal.wav',.2,3.0,fout=.5)],
 'uiClick':[clip(S+'Cinematic Sound Design - Interface & Infographics/Interface Pop High Short.wav',peak=.5)],
 'uiConfirm':[clip(S+'Cinematic Sound Design - Interface & Infographics/Interface Accept Glassy Snap.wav',peak=.6)],
 'uiDeny':[clip(S+'Cinematic Sound Design - System & UI Feedback Elements/Interface Deny Low Fat Dark.wav',peak=.6)],
 'uiSelect':[clip(S+'Cinematic Sound Design - System & UI Feedback Elements/Interface Sci-Fi Ping Down.wav',peak=.55)],
 'uiPanel':[clip(S+'Cinematic Sound Design - Ultra Transitions & Impacts/Woosh Sweep Slide Infographics Basic.wav',peak=.5)],
 'yourTurn':[clip(S+'Cinematic Sound Design - System & UI Feedback Elements/Interface Arp Reveal Down Long.wav',peak=.6)],
 'reward':[clip(S+'Epic Stock Media - Fantasy Game 2 - Sound Kit for Enchanted Realms/UIAlert_Collect Scifi Futuristic Electronic Bass Burst Sweep Heavy 04_ESM_FG2.wav',peak=.65)],
 'victory':[clip(S+'Epic Stock Media - Anime Game/DSGNStngr_Power Up Bright Positive Successful Light Saturation Crash Shimmer 05_ESM_AG.wav',peak=.7)],
 'enemyTurn':[clip(S+'Cinematic Sound Design - Ultra Transitions & Impacts/Transition Braam Slow Dark Creepy.wav',0,3.4,fout=.4,peak=.7)],
 'impactChord':[clip(S+'Cinematic Sound Design - Ultra Transitions & Impacts/Impact Hit Rapid Chord Reverb.wav',0,2.6,fout=.4,peak=.75)],
 'ambient':[loop(S+'Cinematic Sound Design - Sci-Fi Drones/Roomtone Space Ship Interior Muted.wav',5,20)],
}
os.makedirs('clips',exist_ok=True); out={}; tot=0; rep=[]
for k,arr in P.items():
    out[k]=[]
    for i,x in enumerate(arr):
        b=enc(x,24 if k=='ambient' else (32 if k.startswith('ui') else 40)); tot+=len(b)
        open(f'clips/{k}_{i}.ogg','wb').write(b); out[k].append(base64.b64encode(b).decode())
        rep.append(f'{k}_{i} {len(x)/SR:.2f}s {len(b)/1024:.1f}KB')
print('\n'.join(rep)); print('TOTAL',tot/1024,'KB', 'b64', sum(len(s) for v in out.values() for s in v)/1024,'KB')
js='// v53-F recorded sound clips: Kenney (CC0) and Sonniss GDC 2026 bundle (royalty free, no attribution required). Mono Ogg Opus, base64.\n'
js+='const SFX_DATA='+json.dumps(out,separators=(',',':'))+';\n'
open('sfx_data.js','w').write(js); print('sfx_data.js',os.path.getsize('sfx_data.js')/1024,'KB')
