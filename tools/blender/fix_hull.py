# post-fix exported hull JSON: keep main body, crop thin outliers, reorient. usage: fix.py file.json ops...
import json,base64,sys,numpy as np
f=sys.argv[1]; ops=sys.argv[2:]; j=json.load(open(f))
P=np.frombuffer(base64.b64decode(j['p']),np.int16).astype(np.float64).reshape(-1,3)/32767*np.array(j['ext'])
N=np.frombuffer(base64.b64decode(j['q']),np.int8).astype(np.float64).reshape(-1,3)/127
I=np.frombuffer(base64.b64decode(j['i']),np.uint32 if j.get('i32') else np.uint16).astype(np.int64).reshape(-1,3)
def comps(I,n):
    par=np.arange(n)
    def find(a):
        while par[a]!=a: par[a]=par[par[a]]; a=par[a]
        return a
    for a,b,c in I:
        ra,rb,rc=find(a),find(b),find(c); par[rb]=ra; par[find(rc)]=ra
    return np.array([find(i) for i in range(n)])
for op in ops:
    if op=='keep_main':
        lab=comps(I,len(P)); tl=lab[I[:,0]]; u,cnt=np.unique(tl,return_counts=True); m=u[np.argmax(cnt)]
        mp=P[np.unique(I[tl==m])]; lo,hi=mp.min(0),mp.max(0); pad=(hi-lo)*.08; lo-=pad; hi+=pad
        keep=np.zeros(len(I),bool)
        for c in u:
            sel=tl==c; cen=P[np.unique(I[sel])].mean(0)
            if c==m or np.all((cen>=lo)&(cen<=hi)): keep|=sel
        print('keep_main', len(u),'components, kept tris',keep.sum(),'of',len(I)); I=I[keep]
    if op.startswith('crop'):
        q=float(op.split(':')[1]) if ':' in op else .5; C=P[I].mean(1); used=P[np.unique(I)]
        lo,hi=np.percentile(used,q,0),np.percentile(used,100-q,0); keep=np.all((C>=lo)&(C<=hi),1); print('crop kept',keep.sum(),'of',len(I)); I=I[keep]
    R=None
    if op in('flat','tall'):
        used=np.unique(I); Q=P[used]-P[used].mean(0); w,V=np.linalg.eigh(np.cov(Q.T)); big,mid,small=V[:,2],V[:,1],V[:,0]
        if op=='flat': ex,ey=big,small
        else: ey,ex=big,mid
        if ey[1]<0: ey=-ey
        ez=np.cross(ex,ey); R=np.stack([ex,ey,ez])
    if op=='swapxz': R=np.array([[0,0,-1.],[0,1,0],[1,0,0]])
    if op=='flipx': R=np.diag([-1.,1,-1])
    if op=='flipy': R=np.diag([1.,-1,-1])
    if R is not None: P=P@R.T; N=N@R.T; print('rotated',op)
# compact, recentre, normalise (x length 1, or max extent 1 for tall)
used=np.unique(I); remap=-np.ones(len(P),np.int64); remap[used]=np.arange(len(used)); P=P[used]; N=N[used]; I=remap[I]
mn,mx=P.min(0),P.max(0); P-= (mn+mx)/2; L=(mx-mn)[0] if 'tall' not in ops else (mx-mn).max(); P/=L
ext=np.abs(P).max(0)+1e-6; j['ext']=ext.tolist(); j['size']=((mx-mn)/L).tolist(); j['n']=len(P); j['t']=len(I); j['i32']=len(P)>=65535
j['p']=base64.b64encode(np.round(P/ext*32767).astype(np.int16).tobytes()).decode(); j['q']=base64.b64encode(np.round(N*127).astype(np.int8).tobytes()).decode()
j['i']=base64.b64encode(I.astype(np.uint32 if j['i32'] else np.uint16).tobytes()).decode(); j.pop('a',None)
json.dump(j,open(f,'w')); print(f,'tris',len(I),'size',[round(x,3) for x in j['size']])
