"""Geometry, camera fitting and renders for issue 532. No AI geometry ships."""
import json
import math
from pathlib import Path
import sys
import numpy as np

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(REPO / "tools/blender/r209"))

PALETTE = {"hull": (.20, .16, .135, 1), "red": (.25, .065, .045, 1),
           "steel": (.26, .26, .25, 1), "gun": (.085, .085, .082, 1),
           "purple": (.16, .065, .21, 1), "dark": (.035, .035, .035, 1),
           "open": (.17, .18, .19, 1), "lamp": (.6, .035, .012, 1)}


def unit(v):
    v = np.array(v, dtype=float); return v / np.linalg.norm(v)


def parameters(big):
    return dict(width=1.0, height=1.0, house=1.0, bow=1.0, aft=1.0,
                hooks=1.0, engines=1.0, yaw=0.0, bow_width=1.0,
                mid_width=1.0, aft_width=1.0, stern_height=1.0, stern_end=.94)


class Model:
    def __init__(self, data, p=None):
        self.data = data; self.p = p or parameters(data["big"]); self.parts = []

    def add(self, name, verts, faces, mat, fid=None):
        v = np.array(verts, dtype=float)
        v[:, 1] *= self.p["width"]; v[:, 2] *= self.p["height"]
        if "section_width" in self.p:
            st=.5-v[:,0]; knots=np.linspace(0,1,7)
            v[:,1] *= np.interp(st,knots,self.p["section_width"])
            v[:,2] += np.interp(st,knots,self.p["section_lift"])
        if fid in self.p.get("feature_deltas",{}):
            v += np.array(self.p["feature_deltas"][fid])
        v = v*self.p.get("model_scale",1) + np.array(self.p.get("model_shift",[0,0,0]))
        if fid in self.p.get("mount_offsets",{}):v+=np.array(self.p["mount_offsets"][fid])
        self.parts.append(dict(name=name, v=v, faces=faces, mat=mat, feature=fid))

    def box(self, name, center, size, mat="hull", fid=None):
        signs = np.array([[-1,-1,-1], [1,-1,-1], [1,1,-1], [-1,1,-1],
                          [-1,-1,1], [1,-1,1], [1,1,1], [-1,1,1]])
        self.add(name, signs*np.array(size)/2 + center,
                 [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)], mat, fid)

    def cylinder(self, name, start, end, radius, mat="gun", fid=None, n=12, r2=None, cap=True):
        a = np.array(start); b = np.array(end); direction = unit(b-a)
        side = unit(np.cross(direction, [0,0,1] if abs(direction[2]) < .9 else [0,1,0]))
        up = np.cross(direction, side); t = np.arange(n)*2*math.pi/n
        ring = np.cos(t)[:,None]*side + np.sin(t)[:,None]*up
        v = np.concatenate([a+radius*ring, b+(radius if r2 is None else r2)*ring])
        faces = [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
        if cap: faces += [tuple(range(n-1,-1,-1)), tuple(range(n,2*n))]
        self.add(name, v, faces, mat, fid)

    def loft(self, name, stations, widths, bots, tops, mat="hull", fid=None):
        vs = []
        for s,w,b,t in zip(stations,widths,bots,tops):
            vs.extend([[.5-s,y,z] for y,z in
                       [(-w*.64,b),(w*.64,b),(w,b+.20*(t-b)),(w,t-.40*(t-b)),
                        (w*.57,t),(-w*.57,t),(-w,t-.40*(t-b)),(-w,b+.20*(t-b))]])
        faces = [tuple(range(7,-1,-1))]
        for k in range(len(stations)-1):
            faces += [(k*8+j,k*8+(j+1)%8,(k+1)*8+(j+1)%8,(k+1)*8+j) for j in range(8)]
        faces += [tuple(range((len(stations)-1)*8,len(stations)*8))]
        self.add(name,vs,faces,mat,fid)

    def build(self):
        big = self.data["big"]; p = self.p
        s = [.11,.18,.32,.49,.65,.80,.91]
        w = np.array([.12,.18,.225,.23,.23,.205,.16]) * (1 if big else .92)
        w[:2] *= p["bow_width"]; w[2:5] *= p["mid_width"]; w[5:] *= p["aft_width"]
        z = np.array([.045,.09,.105,.105,.11,.095,.04])
        b = np.array([-.095,-.125,-.14,-.14,-.13,-.10,-.06])
        self.loft("M01_hull_envelope",s,w,b,z)
        self.loft("M07_aft_equipment_body",[.80,.87,p["stern_end"]],
                  [.18,.18,.16],[-.06,-.06,-.04],
                  [.13*p["stern_height"],.13*p["stern_height"],.09*p["stern_height"]],"red")
        if big:
            self.loft("M08_aft_engine_saddle",[.86,.92,.985],[.22,.22,.176],
                      [.02,.02,.02],[.17,.17,.136],"steel")
        # A sloping armour crown; separate masses pin the deck edge and bridge.
        self.loft("M02_foredeck",[.17,.29,.48,.63],[.055,.10,.11,.10],
                  [.03,.07,.09,.09],[.06,.115,.145,.16],"steel")
        self.loft("M03_shoulder",[.50,.57,.70,.84],[.105,.145,.14,.09],
                  [.07,.08,.08,.05],[.10,.16,.20,.17],"red")
        h = .22 if big else .25
        self.loft("M04_bridge",[.68,.73,.85,.89],[.085,.11,.11,.075],
                  [.09,.09,.06,.04],[.15,h*p["house"],h*p["house"],.12],"hull")
        self.box("M05_bridge_aperture",[-.23,0,h*.83],[.025,.17,.022],"dark")
        # Explicitly provisional closure, with no invented belly equipment.
        self.loft("TBD_belly_closure",[.18,.35,.65,.86],[.11,.13,.13,.08],
                  [-.127,-.141,-.131,-.09],[-.12,-.13,-.12,-.08],"open")
        # Mismatched plate zones and flank sponsons stay fixed across views.
        for side in [-1,1]:
            self.box("M06_sponson_"+str(side),[-.22,side*.212,-.015],[.25,.09,.105],"red")
            for i in range(5):
                st=.25+i*.115
                self.box(f"P_flank_{side}_{i}",[.5-st,side*(.195 if st<.7 else .19),.045],
                         [.08,.035,.018],"red" if i%2 else "steel")
        self.box("P_prow_patch",[.245,-.052,.108],[.14,.065,.008],"purple" if big else "red")
        if big: self.box("P_crystal_removed",[.035,.19,.065],[.12,.045,.01],"steel")
        for f in self.data["features"]:
            fid=f["id"]; k=f["kind"]; s=f["station"]; y=f["offset"]; z=f["height"]
            c=np.array([.5-s,y,z]); size=np.array(f["size"]); aim=unit(f["aim"])
            if k.endswith("gun"):
                self.box(fid+"_saddle",c-[0,0,.015],size*[.62,1.2,.6],"steel",fid)
                self.box(fid+"_housing",c,size*[.8,1.1,1.2],"gun",fid)
                count=2 if k=="twin_gun" else 1
                lateral=unit(np.cross(aim,[0,0,1]))
                for j in range(count):
                    cc=c + lateral*(j-(count-1)/2)*size[1]*.60
                    start=cc+aim*size[0]*.25; end=cc+aim*size[0]*1.6
                    self.cylinder(fid+f"_barrel{j+1}",start,end,size[1]*.16,"steel",fid,n=8)
                    self.cylinder(fid+f"_muzzle{j+1}",end-aim*.003,end+aim*.002,size[1]*.20,"gun",fid,n=8)
            elif k in ("engine","intake"):
                # Hollow cones and dark inner recesses, never a glowing cap.
                a=c-aim*size[0]*.4; e=c+aim*size[0]*.5
                self.cylinder(fid+"_shell",a,e,size[1]*.5,"steel",fid,n=16,cap=False)
                self.cylinder(fid+"_lip",e-aim*.006,e+aim*.006,size[1]*.52,"gun",fid,n=16,cap=False)
                self.cylinder(fid+"_recess",e-aim*.012,e-aim*.011,size[1]*.44,"dark",fid,n=16)
                self.box(fid+"_mount",c-[0,0,size[1]*.3],size*[.75,.7,.35],"red",fid)
            elif k=="dish":
                r=size[0]
                self.box(fid+"_seat",c-[0,0,r*.75],[r*.65,r*.65,r*.5],"gun",fid)
                side=unit(np.cross(aim,[0,0,1])); up=np.cross(side,aim)
                vs=[c-aim*r*.18]; n=20
                for i in range(n):
                    t=i*2*math.pi/n; vs.append(c+r*(math.cos(t)*side+math.sin(t)*up))
                faces=[(0,i+1,(i+1)%n+1) for i in range(n)]
                self.add(fid+"_bowl",vs,faces,"steel",fid)
                self.cylinder(fid+"_feed",c-aim*r*.15,c+aim*r*.45,r*.055,"gun",fid,n=8)
            elif k=="hook":
                # Articulated boarding jaws. No anchor, keel or maritime hook.
                self.cylinder(fid+"_hinge",c+[0,-.016,.02],c+[0,.016,.02],.026,"gun",fid)
                points=[c+[0,0,.03],c+[.035,0,-.03],c+[.075,0,-.045],c+[.11,0,-.022]]
                # Normalize forward extent so claw tip defines station zero.
                points[-1][0]=.5
                for j in range(3):
                    self.cylinder(fid+f"_jaw{j}",points[j],points[j+1],.012-j*.003,"steel",fid,n=6)
            elif k=="chain":
                # A continuous chain run represented by connected links.
                for j in range(24):
                    st=.20+j*.023; zz=.10-.032*math.sin(j*math.pi/23)
                    self.cylinder(fid+f"_link{j}",[.5-st,y,zz],[.5-st-.019,y,zz-.002],.003,"gun",fid,n=6)
            elif k=="launcher":
                self.box(fid+"_seat",c-[0,0,.022],[.14,.145,.025],"gun",fid)
                for row in range(2):
                    for col in range(5):
                        cc=c+[0,(col-2)*.026,(row-.5)*.026]
                        self.cylinder(fid+f"_tube{row*5+col+1}",cc-[.055,0,0],cc+[.055,0,0],.011,"steel",fid,n=10,cap=False)
                        self.cylinder(fid+f"_mouth{row*5+col+1}",cc+[.050,0,0],cc+[.051,0,0],.009,"dark",fid,n=10)
        if self.p.get("mount_braces") or self.p.get("snap_chains"):
            body=[]
            for part in self.parts:
                if part["feature"] is None:
                    for face in part["faces"]:
                        body.extend([[part["v"][face[0]],part["v"][face[i]],part["v"][face[i+1]]] for i in range(1,len(face)-1)])
            body=np.array(body);vertices=body.reshape(-1,3)
            if self.p.get("auto_seat"):
                for f in self.data["features"]:
                    fid=f["id"];k=f["kind"];parts=[q for q in self.parts if q["feature"]==fid];delta=np.zeros(3)
                    if k in ("dish","launcher") or fid=="U":
                        anchor=next((q for q in parts if q["name"].endswith(("_seat","_saddle"))),None)
                        if anchor is None:continue
                        c=anchor["v"].mean(0);surface=surface_height(body,c[:2])
                        if surface is not None:delta[2]=surface-anchor["v"][:,2].min()+.001
                    elif k.endswith("gun"):
                        anchor=next(q for q in parts if q["name"].endswith("_saddle"));c=anchor["v"].mean(0);side=1 if f["offset"]>0 else -1
                        surface=surface_height(body,c[[0,2]],axis=1,maximum=side>0)
                        if surface is not None:
                            inner=anchor["v"][:,1].min() if side>0 else anchor["v"][:,1].max()
                            delta[1]=surface-inner-side*.001
                    for part in parts:part["v"]+=delta
            if self.p.get("snap_chains"):
                for part in self.parts:
                    if part["name"].startswith(("C1_link","C2_link")):
                        c=part["v"].mean(0);z=surface_height(body,c[:2])
                        if z is not None:part["v"][:,2]+=z+.003-c[2]
            if self.p.get("mount_braces"):
                for f in self.data["features"]:
                    if f["kind"] not in ("engine","intake","hook"):continue
                    anchors=[q for q in self.parts if q["feature"]==f["id"] and q["name"].endswith(("_mount","_hinge"))]
                    if not anchors:continue
                    c=anchors[0]["v"].mean(0);v=vertices[np.argmin(np.linalg.norm(vertices-c,axis=1))]
                    axis=unit(v-c);side=unit(np.cross(axis,[0,0,1] if abs(axis[2])<.9 else [0,1,0]));up=np.cross(axis,side)
                    n=8;t=np.arange(n)*2*math.pi/n;ring=(np.cos(t)[:,None]*side+np.sin(t)[:,None]*up)*.012
                    vs=np.r_[c+ring,v+axis*.006+ring]
                    faces=[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]+[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
                    self.parts.append(dict(name=f["id"]+"_TBD_mount_brace",v=vs,faces=faces,mat="open",feature=f["id"]))
        return self

    def triangles(self):
        out=[]
        for part in self.parts:
            for f in part["faces"]:
                out.extend([[part["v"][f[0]],part["v"][f[i]],part["v"][f[i+1]]] for i in range(1,len(f)-1)])
        return np.array(out)


def geometry(root):
    for code in ("corsair_A16","corsair_A17"):
        p=root/code; data=json.loads((p/"inputs.json").read_text())
        model=Model(data).build(); np.savez_compressed(p/"blockout_initial.npz",tris=model.triangles())
        print("GEOMETRY",code,len(model.triangles()),flush=True)


def fit(root):
    from scipy import optimize
    from PIL import Image
    import silhouette4 as sil
    for code in ("corsair_A16","corsair_A17"):
        p=root/code; im=Image.open(p/"concept_cut.png")
        # Preserve aspect by padding to square, never stretching the picture.
        square=Image.new("RGBA",(1920,1920)); square.alpha_composite(im,(0,320))
        square.resize((1024,1024),Image.Resampling.LANCZOS).save(p/"concept_square.png")
        data=json.loads((p/"inputs.json").read_text()); T=np.load(p/"blockout_initial.npz")["tris"]
        sil.fit(str(p/"concept_square.png"),str(p/"blockout_initial.npz"),str(p/"concept_camera.json"))
        cam=json.loads((p/"concept_camera.json").read_text())["camera"]
        C=sil.concept_mask(p/"concept_square.png",256)
        keys=["width","height","house","bow_width","mid_width","aft_width","stern_height","stern_end"]
        base=parameters(data["big"])
        def loss(x):
            pr=dict(base); pr.update(zip(keys,x)); m=Model(data,pr).build()
            return -sil.iou(sil.raster(m.triangles(),cam,256),C)
        bounds=[(.85,1.2),(.72,1.3),(.75,1.2),(.8,1.35),(.85,1.2),(.8,1.2),(.8,1.5),(.90,.97)]
        res=optimize.differential_evolution(loss,bounds,maxiter=18,popsize=5,seed=532,polish=False)
        base.update(zip(keys,res.x.tolist())); T=Model(data,base).build().triangles()
        np.savez_compressed(p/"blockout_fitted.npz",tris=T)
        (p/"parameters.json").write_text(json.dumps(base,indent=2))
        # One further camera fit, then the camera is frozen for final scoring.
        sil.fit(str(p/"concept_square.png"),str(p/"blockout_fitted.npz"),str(p/"concept_camera.json"))
        sil.score(str(p/"concept_square.png"),str(p/"concept_camera.json"),str(p),[code+"="+str(p/"blockout_fitted.npz")])
        print("FIT",code,flush=True)


def refine(root):
    from scipy import optimize
    import silhouette4 as sil
    for code in ("corsair_A16","corsair_A17"):
        p=root/code; data=json.loads((p/"inputs.json").read_text()); base=json.loads((p/"parameters.json").read_text())
        cam=json.loads((p/"concept_camera.json").read_text())["camera"]
        # A loft with seven measured sections. Fit width and vertical section
        # centres, preserving real depth and one consistent 3D hull throughout.
        start=np.r_[base.get("section_width",[1]*7),base.get("section_lift",[0]*7),
                    cam["az"],cam["el"],cam["roll"],cam["focal"],cam["cx"],cam["cy"]]
        bounds=[(.72,1.4)]*7+[(-.08,.08)]*7+[(cam["az"]-8,cam["az"]+8),(cam["el"]-7,cam["el"]+7),
                (cam["roll"]-5,cam["roll"]+5),(cam["focal"]*.92,cam["focal"]*1.08),
                (cam["cx"]-25,cam["cx"]+25),(cam["cy"]-25,cam["cy"]+25)]
        for n in (256,512):
            C=sil.concept_mask(p/"concept_square.png",n)
            def loss(x):
                pp=dict(base); pp["section_width"]=x[:7].tolist(); pp["section_lift"]=x[7:14].tolist()
                cc=dict(cam); cc.update(zip(("az","el","roll","focal","cx","cy"),x[14:]))
                T=Model(data,pp).build().triangles()
                return -sil.iou(sil.raster(T,cc,n),C)
            res=optimize.minimize(loss,start,method="Powell",bounds=bounds,
                                  options=dict(maxiter=9,maxfev=1600,xtol=.001,ftol=.0002))
            if loss(res.x)<loss(start): start=res.x
            print("REFINE",code,n,round(-loss(start),4),flush=True)
        base["section_width"]=start[:7].tolist(); base["section_lift"]=start[7:14].tolist()
        cam.update(zip(("az","el","roll","focal","cx","cy"),start[14:].tolist()))
        (p/"parameters.json").write_text(json.dumps(base,indent=2)); (p/"concept_camera.json").write_text(json.dumps(dict(camera=cam,image=1024),indent=2))
        np.savez_compressed(p/"blockout_fitted.npz",tris=Model(data,base).build().triangles())
        sil.score(str(p/"concept_square.png"),str(p/"concept_camera.json"),str(p),[code+"="+str(p/"blockout_fitted.npz")])


def sockets(root):
    from scipy import optimize
    import silhouette4 as sil
    for code in ("corsair_A16","corsair_A17"):
        p=root/code;data=json.loads((p/"inputs.json").read_text());pr=json.loads((p/"parameters.json").read_text())
        cam=json.loads((p/"concept_camera.json").read_text())["camera"]; C=sil.concept_mask(p/"concept_square.png",512)
        model=Model(data,pr).build(); fixed=[]; groups={}
        for part in model.parts:
            tris=[]
            for face in part["faces"]:
                tris.extend([[part["v"][face[0]],part["v"][face[i]],part["v"][face[i+1]]] for i in range(1,len(face)-1)])
            if part["feature"]:groups.setdefault(part["feature"],[]).extend(tris)
            else:fixed.extend(tris)
        fixed=np.array(fixed);groups={k:np.array(v) for k,v in groups.items()}
        ids=list(groups); old=pr.get("feature_deltas",{})
        # Translate whole fittings, including their saddles. X/Z only for
        # flank guns; all axes for the forward claws and cylindrical units.
        variable=[]
        for fid in ids:
            f=next(f for f in data["features"] if f["id"]==fid)
            axes=(0,2) if f["kind"].endswith("gun") else (0,1,2)
            if f["kind"] in ("chain","launcher"):continue
            for axis in axes:variable.append((fid,axis))
        # Start from zero incremental motion because groups already carry old.
        start=np.zeros(len(variable));bounds=[(-.045,.045)]*len(variable)
        def loss(x):
            delta={fid:np.zeros(3) for fid in ids}
            for (fid,axis),v in zip(variable,x):delta[fid][axis]=v
            T=np.concatenate([fixed]+[groups[fid]+delta[fid] for fid in ids])
            return -sil.iou(sil.raster(T,cam,512),C)
        res=optimize.minimize(loss,start,method="Powell",bounds=bounds,options=dict(maxiter=5,maxfev=2200,xtol=.001,ftol=.0001))
        if loss(res.x)<loss(start):start=res.x
        delta={fid:np.array(old.get(fid,[0,0,0]),float) for fid in ids}
        for (fid,axis),v in zip(variable,start):delta[fid][axis]+=v
        pr["feature_deltas"]={k:v.tolist() for k,v in delta.items()}
        (p/"parameters.json").write_text(json.dumps(pr,indent=2))
        np.savez_compressed(p/"blockout_fitted.npz",tris=Model(data,pr).build().triangles())
        sil.score(str(p/"concept_square.png"),str(p/"concept_camera.json"),str(p),[code+"="+str(p/"blockout_fitted.npz")])
        print("SOCKET FIT",code,flush=True)


def finalize(root):
    import silhouette4 as sil
    for code in ("corsair_A16","corsair_A17"):
        p=root/code;data=json.loads((p/"inputs.json").read_text());pr=json.loads((p/"parameters.json").read_text())
        if "model_scale" in pr:continue
        T=Model(data,pr).build().triangles();lo=T[:,:,0].min();hi=T[:,:,0].max();span=hi-lo;mid=(lo+hi)/2
        # Calibrate the complete design, fittings included, to the game length.
        # Uniform scale retains every proportion and projected pixel. The
        # camera receives the same similarity transform, not a new fit.
        pr["model_scale"]=1/span;pr["model_shift"]=[-mid/span,0,0]
        cj=json.loads((p/"concept_camera.json").read_text());cam=cj["camera"]
        cam["target"]=(np.array(cam.get("target",[0,0,-.01]))/span+np.array(pr["model_shift"])).tolist();cam["dist"]/=span
        (p/"parameters.json").write_text(json.dumps(pr,indent=2));(p/"concept_camera.json").write_text(json.dumps(cj,indent=2))
        np.savez_compressed(p/"blockout_fitted.npz",tris=Model(data,pr).build().triangles())
        sil.score(str(p/"concept_square.png"),str(p/"concept_camera.json"),str(p),[code+"="+str(p/"blockout_fitted.npz")])


def surface_height(tris,xy,axis=2,maximum=True):
    axes=[a for a in range(3) if a!=axis]; uv=tris[:,:,axes]; q=np.array(xy)
    v0=uv[:,1]-uv[:,0];v1=uv[:,2]-uv[:,0];v2=q-uv[:,0]
    den=v0[:,0]*v1[:,1]-v1[:,0]*v0[:,1];good=np.abs(den)>1e-10
    den=np.where(good,den,1);a=(v2[:,0]*v1[:,1]-v1[:,0]*v2[:,1])/den
    b=(v0[:,0]*v2[:,1]-v2[:,0]*v0[:,1])/den
    hit=good&(a>=-1e-7)&(b>=-1e-7)&(a+b<=1.0000001)
    if not hit.any():return None
    z=tris[:,0,axis]+a*(tris[:,1,axis]-tris[:,0,axis])+b*(tris[:,2,axis]-tris[:,0,axis])
    return float(z[hit].max() if maximum else z[hit].min())


def barrel_hits(model):
    all_tris=[];labels=[];owners=[]
    for q in model.parts:
        for f in q["faces"]:
            for j in range(1,len(f)-1):
                all_tris.append(q["v"][[f[0],f[j],f[j+1]]]);labels.append(q["name"]);owners.append(q["feature"])
    triangles=np.array(all_tris);labels=np.array(labels);owners=np.array(owners,dtype=object);hits=[]
    for gun in (q for q in model.parts if "_barrel" in q["name"]):
        n=len(gun["v"])//2;a=gun["v"][:n].mean(0);b=gun["v"][n:].mean(0);direction=b-a
        t=triangles;e1=t[:,1]-t[:,0];e2=t[:,2]-t[:,0];h=np.cross(direction,e2)
        det=np.einsum("ij,ij->i",e1,h);ok=np.abs(det)>1e-9;inv=np.where(ok,1/np.where(ok,det,1),0)
        s=a-t[:,0];u=inv*np.einsum("ij,ij->i",s,h);cross=np.cross(s,e1)
        v=inv*np.einsum("j,ij->i",direction,cross);tt=inv*np.einsum("ij,ij->i",e2,cross)
        valid=ok&(u>=0)&(v>=0)&(u+v<=1)&(tt>.1)&(tt<.99)&(owners!=gun["feature"])
        for label in sorted(set(labels[valid])):hits.append([gun["name"],str(label)])
    return hits


def inventory(root):
    import silhouette4 as sil
    from PIL import Image,ImageDraw,ImageFont
    from build_sheets_532_layout import point
    targets={
      "corsair_A16":{"F1":(300,552),"F2":(329,486),"F3":(535,369),"F4":(572,337),"F5":(754,268),
                     "V1":(877,229),"V2":(961,205),"G1":(1135,763),"G2":(1421,623),
                     "T1":(1151,551),"T2":(1398,478),"T3":(1396,359),"U":(1264,106)},
      "corsair_A17":{"F1":(526,427),"F2":(586,348),"F3":(681,299),"U":(789,232),
                     "G1":(1322,586),"G2":(1419,517),"g":(1126,839),"J1":(1171,678),
                     "J2":(1308,738),"J3":(1255,309)}}
    for code,pins in targets.items():
        p=root/code;data=json.loads((p/"inputs.json").read_text());pr=json.loads((p/"parameters.json").read_text())
        cam=json.loads((p/"concept_camera.json").read_text())["camera"];pos,forward,right,up=sil.cam_basis(cam)
        valid={f["id"] for f in data["features"]};pr["feature_deltas"]={k:v for k,v in pr.get("feature_deltas",{}).items() if k in valid}
        for f in data["features"]:
            if f["id"] not in pins:continue
            old=np.array(pr.get("feature_deltas",{}).get(f["id"],[0,0,0]));pr["feature_deltas"][f["id"]]=[0,0,0]
            c=point(f,pr);px,py=pins[f["id"]];uv=np.array([px,py+320])*1024/1920
            ray=forward+right*(uv[0]-cam["cx"])/cam["focal"]-up*(uv[1]-cam["cy"])/cam["focal"]
            # Fix the plausible flank lane. Recover station and height through
            # the fitted perspective camera; auto-seat then finds the hull.
            axis=2 if f["id"]=="U" else 1;t=(c[axis]-pos[axis])/ray[axis];target=pos+t*ray
            delta=(target-c)/pr.get("model_scale",1)
            pr["feature_deltas"][f["id"]]=delta.tolist()
        (p/"parameters.json").write_text(json.dumps(pr,indent=2))
        (p/"gun_inventory_pixels.json").write_text(json.dumps(pins,indent=2))
        im=Image.open(data["beauty"]).convert("RGB");dr=ImageDraw.Draw(im);fo=ImageFont.truetype("C:/Windows/Fonts/consola.ttf",26)
        dr.rectangle((0,0,1110,50),fill=(40,40,40));dr.text((16,8),code+" / VISIBLE GUN MOUNTS / TABLE IDs",font=fo,fill=(255,220,140))
        for fid,(x,y) in pins.items():
            dr.ellipse((x-14,y-14,x+14,y+14),outline=(255,180,75),width=3)
            dr.text((x+17,y-23),fid,font=fo,fill=(255,210,110),stroke_width=2,stroke_fill=(0,0,0))
        im.save(p/"gun_inventory.jpg",quality=94);im.thumbnail((1080,720));im.save(root/(code+"_inventory_preview.jpg"),quality=94)
        np.savez_compressed(p/"blockout_fitted.npz",tris=Model(data,pr).build().triangles())
        sil.score(str(p/"concept_square.png"),str(p/"concept_camera.json"),str(p),[code+"="+str(p/"blockout_fitted.npz")])


def camera_tune(root):
    from scipy import optimize
    import silhouette4 as sil
    for code in ("corsair_A16","corsair_A17"):
        p=root/code;data=json.loads((p/"inputs.json").read_text());pr=json.loads((p/"parameters.json").read_text())
        cj=json.loads((p/"concept_camera.json").read_text());cam=cj["camera"];T=Model(data,pr).build().triangles()
        keys=["az","el","roll","dist","focal","cx","cy"];start=np.array([cam[k] for k in keys])
        for n in (512,1024):
            C=sil.concept_mask(p/"concept_square.png",n)
            def loss(x):
                cc=dict(cam);cc.update(zip(keys,x));return -sil.iou(sil.raster(T,cc,n),C)
            steps=np.array([1,.7,.4,.04,20,4,4])*(512/n)
            simplex=np.array([start]+[start+np.eye(7)[i]*steps[i] for i in range(7)])
            res=optimize.minimize(loss,start,method="Nelder-Mead",options=dict(initial_simplex=simplex,maxiter=600,xatol=.0001,fatol=.000001))
            if loss(res.x)<loss(start):start=res.x
            print("CAMERA",code,n,-loss(start),flush=True)
        cam.update(zip(keys,start.tolist()));(p/"concept_camera.json").write_text(json.dumps(cj,indent=2))
        np.savez_compressed(p/"blockout_fitted.npz",tris=T)
        sil.score(str(p/"concept_square.png"),str(p/"concept_camera.json"),str(p),[code+"="+str(p/"blockout_fitted.npz")])


def seat(root):
    import silhouette4 as sil
    for code in ("corsair_A16","corsair_A17"):
        p=root/code;data=json.loads((p/"inputs.json").read_text());pr=json.loads((p/"parameters.json").read_text())
        pr.pop("mount_offsets",None);model=Model(data,pr).build()
        body=[]
        for part in model.parts:
            if part["feature"] is None:
                for f in part["faces"]:
                    body.extend([[part["v"][f[0]],part["v"][f[i]],part["v"][f[i+1]]] for i in range(1,len(f)-1)])
        body=np.array(body);offsets={}
        for f in data["features"]:
            fid=f["id"];k=f["kind"];parts=[q for q in model.parts if q["feature"]==fid]
            if k in ("dish","launcher") or fid=="U":
                anchor=next((q for q in parts if q["name"].endswith(("_seat","_saddle"))),None)
                if anchor is None:continue
                c=anchor["v"].mean(0);surface=surface_height(body,c[:2])
                if surface is not None:offsets[fid]=[0,0,surface-float(anchor["v"][:,2].min())+.001]
            elif k.endswith("gun"):
                anchor=next(q for q in parts if q["name"].endswith("_saddle"));c=anchor["v"].mean(0)
                side=1 if f["offset"]>0 else -1
                surface=surface_height(body,c[[0,2]],axis=1,maximum=side>0)
                if surface is not None:
                    inner=anchor["v"][:,1].min() if side>0 else anchor["v"][:,1].max()
                    offsets[fid]=[0,surface-inner-side*.001,0]
        pr["mount_offsets"]=offsets
        pr["mount_braces"]=True;pr["snap_chains"]=True
        pr["auto_seat"]=True
        (p/"parameters.json").write_text(json.dumps(pr,indent=2))
        np.savez_compressed(p/"blockout_fitted.npz",tris=Model(data,pr).build().triangles())
        sil.score(str(p/"concept_square.png"),str(p/"concept_camera.json"),str(p),[code+"="+str(p/"blockout_fitted.npz")])
        print("SEATED",code,len(offsets),flush=True)


def render(root):
    import bpy
    from mathutils import Vector
    for code in ("corsair_A16","corsair_A17"):
        p=root/code; data=json.loads((p/"inputs.json").read_text()); L=data["length"]
        params=json.loads((p/"parameters.json").read_text()) if (p/"parameters.json").exists() else None
        model=Model(data,params).build(); bpy.ops.wm.read_factory_settings(use_empty=True)
        scene=bpy.context.scene; scene.render.engine="CYCLES"; scene.cycles.samples=24
        scene.cycles.use_denoising=True; scene.cycles.device="CPU"
        prefs=bpy.context.preferences.addons["cycles"].preferences
        try:
            prefs.compute_device_type="OPTIX";prefs.get_devices()
            for dev in prefs.devices:dev.use=dev.type=="OPTIX"
            if any(dev.use for dev in prefs.devices):scene.cycles.device="GPU"
        except Exception:pass
        scene.world=bpy.data.worlds.new("Flat dark grey"); scene.world.use_nodes=True
        scene.world.node_tree.nodes["Background"].inputs[0].default_value=(.18,.18,.18,1)
        scene.world.node_tree.nodes["Background"].inputs[1].default_value=.8
        scene.render.film_transparent=True; scene.view_settings.view_transform="AgX"
        scene.render.image_settings.file_format="PNG"; scene.render.image_settings.color_mode="RGBA"
        mats={}
        for name,color in PALETTE.items():
            m=bpy.data.materials.new(name); m.diffuse_color=color; m.use_nodes=True
            bs=m.node_tree.nodes.get("Principled BSDF"); bs.inputs["Base Color"].default_value=color
            bs.inputs["Metallic"].default_value=.3; bs.inputs["Roughness"].default_value=.65
            mats[name]=m
        for part in model.parts:
            mesh=bpy.data.meshes.new(part["name"]); mesh.from_pydata((part["v"]*L).tolist(),[],part["faces"]); mesh.update()
            import bmesh
            bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
            obj=bpy.data.objects.new(part["name"],mesh); scene.collection.objects.link(obj); obj.data.materials.append(mats[part["mat"]])
            obj["feature_id"]=part["feature"] or "mass"; obj["purpose"]="Build-sheet stand-in, not game asset"
        def area(name, pos, power, size):
            ld=bpy.data.lights.new(name,"AREA"); ld.energy=power*L*L; ld.shape="DISK"; ld.size=size*L
            ob=bpy.data.objects.new(name,ld); scene.collection.objects.link(ob); ob.location=Vector(pos)*L
            ob.rotation_euler=(-ob.location).to_track_quat("-Z","Y").to_euler()
        area("Key_forward_port_45",[1,1,math.sqrt(2)],110,1.4)
        area("Fill_aft_starboard_20pct",[-1,-1,.4],22,1.4)
        ca=bpy.data.cameras.new("Measured camera"); camera=bpy.data.objects.new("Measured camera",ca); scene.collection.objects.link(camera); scene.camera=camera
        ca.type="ORTHO"; ca.ortho_scale=L*1.2; ca.clip_end=L*100
        scene.render.resolution_x=1200; scene.render.resolution_y=1200; scene.render.resolution_percentage=100
        views={"side":([0,3,0],[0,0,1]),"top":([0,0,3],[1,0,0]),
               "underside":([0,0,-3],[1,0,0]),"bow":([3,0,0],[0,0,1]),
               "stern":([-3,0,0],[0,0,1]),"three_quarter":([1.224745,1.224745,1],[0,0,1])}
        records={}
        for name,(pos,up) in views.items():
            camera.location=Vector(pos)*L; direction=-camera.location.normalized()
            # Camera +Y = requested page-up, projected perpendicular to view.
            u=Vector(up); u=(u-direction*u.dot(direction)).normalized()
            r=direction.cross(u).normalized()
            from mathutils import Matrix
            camera.rotation_euler=Matrix((r,u,-direction)).transposed().to_euler()
            scene.render.filepath=str(p/(name+"_raw.png")); bpy.ops.render.render(write_still=True)
            saved=camera.copy();saved.data=camera.data.copy();saved.name=code+"_"+name+"_ORTHO";scene.collection.objects.link(saved)
            records[name]=dict(type="ORTHO",resolution=[1200,1200],ortho_scale=ca.ortho_scale,
                               pixels_per_world=1200/ca.ortho_scale,position=list(camera.location),
                               rotation=list(camera.rotation_euler),up=up,feature_ids=[f["id"] for f in data["features"]])
        # Fitted concept camera, using exactly the scoring projection.
        cj=json.loads((p/"concept_camera.json").read_text())["camera"]
        az,el,roll=[math.radians(cj[k]) for k in ("az","el","roll")]
        direction=np.array([math.cos(el)*math.cos(az),math.cos(el)*math.sin(az),math.sin(el)])
        pos=np.array(cj.get("target",[0,0,-.01]))+direction*cj["dist"]; forward=-direction
        right=unit(np.cross(forward,[0,0,1])); up=np.cross(right,forward)
        right,up=math.cos(roll)*right+math.sin(roll)*up,-math.sin(roll)*right+math.cos(roll)*up
        camera.location=Vector(pos)*L; camera.rotation_euler=Matrix((Vector(right),Vector(up),Vector(-forward))).transposed().to_euler()
        ca.type="PERSP"; ca.sensor_fit="HORIZONTAL"; ca.sensor_width=36; ca.lens=cj["focal"]*36/1024
        ca.shift_x=(512-cj["cx"])/1024; ca.shift_y=(cj["cy"]-512)/1024
        scene.render.resolution_x=1024; scene.render.resolution_y=1024
        scene.render.filepath=str(p/"fitted_camera_raw.png"); bpy.ops.render.render(write_still=True)
        (p/"render_manifest.json").write_text(json.dumps(dict(code=code,length=L,views=records,parameters=params,
            open_design=data["unresolved"],light="Key +X,+Y,+Z, 45 deg elevation; fill aft-starboard at 20% energy; lights fixed between views"),indent=2))
        scene["notes"]="Issue 532. One geometry set for every view. Grey belly closure TO BE DESIGNED."
        scene["length_world"]=L;scene["parameters_file"]=str(p/"parameters.json")
        scene["shape_reference_file"]=str(p/"shape_reference_v2.glb")
        bpy.ops.wm.save_as_mainfile(filepath=str(p/(code+"_blockout.blend")))


def dispatch(cmd,root):
    if cmd=="geometry": geometry(root)
    elif cmd=="fit": fit(root)
    elif cmd=="refine": refine(root)
    elif cmd=="sockets": sockets(root)
    elif cmd=="finalize": finalize(root)
    elif cmd=="seat": seat(root)
    elif cmd=="inventory": inventory(root)
    elif cmd=="camera_tune": camera_tune(root)
    elif cmd=="render": render(root)
    else:
        from build_sheets_532_layout import dispatch as layout
        layout(cmd,root)
