"""Pack the issue 281 weapon muzzle and impact gas renders into 4x4 atlases.

ComfyUI Python pack_weapons.py BAKE_OUT GODOT_ATLAS_DIR

Same channel recipe as pack_death.py: colour, bidirectional image flow (RG forward, BA backward,
encoded +/- .125 per frame) and optical thickness (tau, lit G, alpha). Muzzle and impact each land in
their own folder under godot/fx/atlases/weapons/ at the death "small" tier size (1024), so the runtime
can load them next to the ship-death atlases. Flow and thickness write lossless import stubs (no
mipmaps, no alpha repair) exactly as pack_death.py does.
"""
import hashlib, json, pathlib, sys
import numpy as np
from PIL import Image, ImageFilter
src,dst=map(pathlib.Path,sys.argv[1:3]); dst.mkdir(parents=True,exist_ok=True)

def blur(x):
    return (x+np.roll(x,1,0)+np.roll(x,-1,0)+np.roll(x,1,1)+np.roll(x,-1,1))/5
def warp(x,u,v):
    yy,xx=np.indices(x.shape); xx=np.clip(xx+u,0,x.shape[1]-1.001); yy=np.clip(yy+v,0,x.shape[0]-1.001)
    xi=xx.astype(int); yi=yy.astype(int); xf=xx-xi; yf=yy-yi
    return (x[yi,xi]*(1-xf)+x[yi,xi+1]*xf)*(1-yf)+(x[yi+1,xi]*(1-xf)+x[yi+1,xi+1]*xf)*yf
def flow(aa,bb):
    u=v=None
    for n in [24,48,96,192]:
        x=np.array(Image.fromarray(aa).resize((n,n),Image.Resampling.BILINEAR),dtype=np.float32)/255
        y=np.array(Image.fromarray(bb).resize((n,n),Image.Resampling.BILINEAR),dtype=np.float32)/255
        if u is None: u=np.zeros_like(x); v=np.zeros_like(x)
        else:
            u=np.array(Image.fromarray(u).resize((n,n),Image.Resampling.BILINEAR))*2
            v=np.array(Image.fromarray(v).resize((n,n),Image.Resampling.BILINEAR))*2
        for _ in range(3):
            yw=warp(y,u,v); gy,gx=np.gradient((x+yw)*.5); dt=yw-x; du=np.zeros_like(x); dv=np.zeros_like(x)
            for __ in range(28):
                ub=blur(du); vb=blur(dv); q=(gx*ub+gy*vb+dt)/(.008+gx*gx+gy*gy); du=ub-gx*q; dv=vb-gy*q
            u+=du; v+=dv
    return np.stack([u/n,v/n],axis=-1)

KINDS = ['muzzle', 'impact']
SIZE = 1024   # the death "small" tier

metadata={}
for kind in KINDS:
    imgs=[Image.open(src/kind/('lit_%02d.png'%i)).convert('RGBA').filter(ImageFilter.GaussianBlur(2.0)) for i in range(16)]
    tile=imgs[0].width; atlases=[Image.new('RGBA',(tile*4,tile*4)) for _ in range(3)]
    alphas=[np.array(im.getchannel('A')) for im in imgs]
    forwards=[flow(alphas[i],alphas[min(i+1,15)]) for i in range(16)]
    backwards=[flow(alphas[i],alphas[max(i-1,0)]) for i in range(16)]
    for i,im in enumerate(imgs):
        raw=np.array(im,dtype=np.float32)/255; alpha=raw[:,:,3]; lum=raw[:,:,:3].mean(2)
        raw[:,:,:3]=np.floor(raw[:,:,:3]*6+.5)/6
        color=Image.fromarray(np.uint8(np.clip(raw,0,1)*255))
        fw=np.array(Image.fromarray(forwards[i][:,:,0]).resize((tile,tile))); fy=np.array(Image.fromarray(forwards[i][:,:,1]).resize((tile,tile)))
        bw=np.array(Image.fromarray(backwards[i][:,:,0]).resize((tile,tile))); by=np.array(Image.fromarray(backwards[i][:,:,1]).resize((tile,tile)))
        motion=Image.fromarray(np.uint8(np.clip(np.stack([fw,fy,bw,by],-1)/.25+.5,0,1)*255))
        tau=-np.log(np.maximum(1-alpha,.005))/5.3
        thick=Image.fromarray(np.uint8(np.clip(np.stack([tau,lum,alpha,alpha],-1),0,1)*255))
        xy=((i%4)*tile,(i//4)*tile)
        for atlas,cell in zip(atlases,[color,motion,thick]): atlas.paste(cell,xy)
    folder=dst/kind; folder.mkdir(parents=True,exist_ok=True)
    for atlas,suffix in zip(atlases,['color','flow','thickness']):
        target=folder/(kind+'_'+suffix+'.png')
        atlas.resize((SIZE,SIZE),Image.Resampling.BILINEAR).save(target)
        if suffix != 'color':
            resource='res://fx/atlases/weapons/'+kind+'/'+target.name
            cache='res://.godot/imported/'+target.name+'-'+hashlib.md5(resource.encode()).hexdigest()+'.ctex'
            target.with_suffix('.png.import').write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\npath="'+cache+'"\n\n[deps]\nsource_file="'+resource+'"\ndest_files=["'+cache+'"]\n\n[params]\ncompress/mode=0\ncompress/normal_map=0\nmipmaps/generate=false\nprocess/fix_alpha_border=false\nprocess/premult_alpha=false\nprocess/hdr_as_srgb=false\ndetect_3d/compress_to=0\n')
    metadata[kind]=dict(frames=16,grid=4,tile=tile,flow_range_uv=.125,max_alpha=int(max(x.max() for x in alphas)),nonempty_frames=int(sum(x.max()>0 for x in alphas)))
metadata['source']=json.loads((src/'bake.json').read_text())
metadata['size_class']=SIZE
(dst/'bake_manifest.json').write_text(json.dumps(metadata,indent=2)+'\n')
print(json.dumps(metadata,indent=2))
