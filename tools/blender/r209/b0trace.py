# Issue 209 round 5: trace B0's own shape, slice by slice (R147: "the hand hull is traced from B0's own shape, section by section").
# Step 1, `slices`: B0 (the whole-hull generation, yaw fixed; sil_dump.py b0 mode writes its triangles) is cut every 0.02 of the
#   ship's length; each cut is drawn on a 0.002 grid, closed and filled (B0's aft hull is an open shell, so each column is also
#   filled top to bottom), and only the main body is kept (the largest piece, nothing above the deck line or outboard of the side
#   blocks, no fins below the belly).
# Step 2, `fit`: one clean half-section is fitted to each slice (flat deck, sharp deck edge, chamfered shoulder, slab side, two-facet
#   tuck, flat belly: 7 points), by Nelder-Mead on the overlap; the overlay sheet shows each fit (red) on its slice (grey).
# The fitted stations, smoothed and squared up by hand, are armA5.HK; tune5.py then moves them by region on the concept outline.
# usage: python3 b0trace.py slices B0.npz SLICES.npz
#        python3 b0trace.py fit SLICES.npz FIT.json SHEET.png
import numpy as np, json, sys
from scipy import ndimage, optimize
from PIL import Image, ImageDraw
G = .002; Y0, Z0 = -.26, -.28; NY, NZ = 260, 280; C = 130

def slice_x(T, x):
    d = T[:, :, 0] - x; s = np.sign(d); m = (s.min(1) < 0) & (s.max(1) > 0); t = T[m]; d = d[m]; pts = []
    for a, b in ((0, 1), (1, 2), (2, 0)):
        da, db = d[:, a], d[:, b]; k = (da * db) < 0; u = np.zeros(len(t)); u[k] = da[k] / (da[k] - db[k])
        pts.append((k, t[:, a, 1:] + (t[:, b, 1:] - t[:, a, 1:]) * u[:, None]))
    S = []
    for i in range(len(t)):
        q = [p[i] for k, p in pts if k[i]]
        if len(q) == 2: S.append(q)
    return np.array(S)

def mask(T, x):
    m = np.zeros((NZ, NY), bool)
    for a, b in slice_x(T, x):
        for t in np.linspace(0, 1, int(max(abs(b - a)) / G * 2) + 2):
            p = a + (b - a) * t; j = int((p[0] - Y0) / G); i = int((p[1] - Z0) / G)
            if 0 <= i < NZ and 0 <= j < NY: m[i, j] = True
    return ndimage.binary_fill_holes(ndimage.binary_closing(m, iterations=2))

def slices(b0, out):
    T = np.load(b0)['tris'].astype(np.float64); xs = np.arange(-.46, .49, .02)
    np.savez_compressed(out, xs=xs, m=np.array([mask(T, x) for x in xs]))

def zcut(x): return .032 if x<-.14 else (.026 if x<.20 else (.016 if x<.42 else .0))
def ycut(x): return .125 if x<-.14 else .152
def prep(m,x):
    h=m[:, C:].copy()
    for j in range(h.shape[1]):
        i=np.nonzero(h[:,j])[0]
        if len(i): h[i.min():i.max()+1,j]=True
    lab,n=ndimage.label(h)
    if n>1:
        sz=ndimage.sum(h,lab,range(1,n+1)); h=lab==(np.argmax(sz)+1)
    h[int((zcut(x)-Z0)/G)+1:,:]=False; h[:,int(ycut(x)/G)+1:]=False
    # fins below the belly are parts, not hull
    h[:int((-.19-Z0)/G),:]=False
    return h
def rast(poly):
    im=Image.new('L',(NY-C,NZ),0); ImageDraw.Draw(im).polygon([(y/G,(z-Z0)/G) for y,z in poly],fill=1); return np.asarray(im)>0
def half(q):
    zt,a,b,c,dd,Ws,f1,f2,f3=q
    a,b,c,dd=abs(a),abs(b),abs(c),abs(dd); f1,f2,f3=[min(1,max(.2,v)) for v in (f1,f2,f3)]
    zs1=zt-a; zs2=zs1-b; zt2=zs2-c; zb=zt2-dd; Wd=Ws*f1; Wt=Ws*f2; Wb=Wt*f3
    return [(0,zt),(Wd,zt),(Ws,zs1),(Ws,zs2),(Wt,zt2),(Wb,zb),(0,zb)]
def fit(sl, out_json, sheet):
    d = np.load(sl); xs = d['xs']; M = d['m']
    out=[]; prev=None
    for x,m in zip(xs,M):
        h=prep(m,x)
        if h.sum()<50: continue
        def L(q): a=rast(half(q)); return -(a&h).sum()/max(1,(a|h).sum())
        ii,jj=np.nonzero(h); zmax=Z0+ii.max()*G; zmin=Z0+ii.min()*G; W=jj.max()*G; H=zmax-zmin
        starts=[[zmax,H*.2,H*.4,H*.2,H*.2,W,.75,.75,.6],[zmax,.01,H*.6,H*.2,H*.15,W*.95,.9,.7,.6]]
        if prev is not None: starts.append(prev)
        best=None
        for s in starts:
            r=optimize.minimize(L,s,method='Nelder-Mead',options=dict(maxiter=3000,xatol=1e-5,fatol=1e-6))
            r=optimize.minimize(L,r.x,method='Nelder-Mead',options=dict(maxiter=3000,xatol=1e-5,fatol=1e-6))
            if best is None or r.fun<best.fun: best=r
        prev=list(best.x); hp=half(best.x)
        out.append(dict(x=round(float(x),3),iou=round(-best.fun,3),half=[(round(a,4),round(b,4)) for a,b in hp]))
        print(out[-1]['x'],out[-1]['iou'],' '.join(f'({a:.3f},{b:+.3f})' for a,b in hp[1:6]),flush=True)
    json.dump(out,open(out_json,'w'),indent=0)
    # overlay image
    cols=8; rows=(len(out)+cols-1)//cols; W2=NY-C
    im=Image.new('RGB',(cols*W2,rows*NZ))
    for k,(o,(x,m)) in enumerate(zip(out,[(x,m) for x,m in zip(xs,M) if prep(m,x).sum()>=50])):
        full=m[:,C:]; h=prep(m,x); a=np.zeros((NZ,W2,3),np.uint8); a[full]=(70,70,70); a[h]=(150,150,150)
        p=rast(o['half']); edge=p^ndimage.binary_erosion(p); a[edge]=(255,60,60)
        for g in range(0,W2,25): a[:,g]=np.maximum(a[:,g],(0,0,90))
        for g in range(0,NZ,25): a[g,:]=np.maximum(a[g,:],(0,0,90))
        t=Image.fromarray(a[::-1]); im.paste(t,((k%cols)*W2,(k//cols)*NZ)); ImageDraw.Draw(im).text(((k%cols)*W2+3,(k//cols)*NZ+3),f"{x:+.2f} {o['iou']:.2f}",fill=(255,255,0))
    im.save(sheet)

if __name__ == '__main__':
    if sys.argv[1] == 'slices': slices(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == 'fit': fit(*sys.argv[2:5])
