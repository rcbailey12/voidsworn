"""Flat sheet layout, evidence checks and local structure/style trial."""
import collections
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import sys
import tempfile
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

REPO=Path(__file__).resolve().parents[2]
DEST=REPO/"docs/ship_pipeline/build_sheets"
GREY=(48,48,48)
WHITE=(230,225,215)
ACCENT=(233,166,91)


def font(n):
    return ImageFont.truetype("C:/Windows/Fonts/consola.ttf",n)


def text(draw,xy,s,size=20,color=WHITE):
    draw.text(xy,s,font=font(size),fill=color)


def flat(path):
    a=Image.open(path).convert("RGBA"); b=Image.new("RGBA",a.size,GREY+(255,)); b.alpha_composite(a); return b.convert("RGB")


def point(f,params):
    c=np.array([.5-f["station"],f["offset"]*params["width"],f["height"]*params["height"]])
    if "section_width" in params:
        c[1]*=np.interp(f["station"],np.linspace(0,1,7),params["section_width"])
        c[2]+=np.interp(f["station"],np.linspace(0,1,7),params["section_lift"])
    c+=np.array(params.get("feature_deltas",{}).get(f["id"],[0,0,0]))
    c=c*params.get("model_scale",1)+np.array(params.get("model_shift",[0,0,0]))
    c+=np.array(params.get("mount_offsets",{}).get(f["id"],[0,0,0]))
    return c


def project(c,view):
    forward={"side":[0,-1,0],"top":[0,0,-1],"underside":[0,0,1],"bow":[-1,0,0],"stern":[1,0,0]}[view]
    up=np.array([1,0,0] if view in ("top","underside") else [0,0,1]); right=np.cross(forward,up)
    return (600+1000*np.dot(c,right),600-1000*np.dot(c,up))


def dashed(draw,a,b,fill=ACCENT,width=2):
    a=np.array(a); b=np.array(b); v=b-a; length=np.linalg.norm(v)
    if not length:return
    for t in np.arange(0,length,12):
        draw.line([tuple(a+v*t/length),tuple(a+v*min(t+6,length)/length)],fill=fill,width=width)


def section_beam(tris):
    # Intersect real triangles with longitudinal stations, including fittings.
    # A bounding box can combine port/starboard extrema at different stations.
    edges=np.concatenate([tris[:,[0,1]],tris[:,[1,2]],tris[:,[2,0]]])
    dx=edges[:,1,0]-edges[:,0,0];good=np.abs(dx)>1e-9;edges=edges[good];dx=dx[good]
    best=(0,0,0,0)
    for x in np.linspace(-.4999,.4999,600):
        t=(x-edges[:,0,0])/dx;hit=(t>=0)&(t<=1)
        if not hit.any():continue
        y=edges[:,0,1]+t*(edges[:,1,1]-edges[:,0,1]);lo=float(y[hit].min());hi=float(y[hit].max())
        if hi-lo>best[0]:best=(hi-lo,.5-x,lo,hi)
    return best


def annotate(p,data,view):
    im=flat(p/(view+"_raw.png")); dr=ImageDraw.Draw(im); L=data["length"]; params=json.loads((p/"parameters.json").read_text())
    from build_sheets_532_geometry import Model
    model=Model(data,params).build()
    beam=section_beam(model.triangles())
    text(dr,(28,20),data["code"]+" | "+view.upper().replace("_"," "),28)
    if view in ("top","underside"):
        for st in np.arange(0,1.01,.1):
            yy=100+st*1000; dr.line((80,yy,95,yy),fill=ACCENT,width=2)
            text(dr,(8,yy-10),f"{st*100:.0f}%",16,ACCENT)
        text(dr,(500,62),"BOW / 0%",18,ACCENT)
        if view=="top":text(dr,(260,92),"Only jaw tips project beyond hull; belly is occluded",14)
    if view=="side":
        for st in np.arange(0,1.01,.1):
            xx=100+st*1000; dr.line((xx,860,xx,875),fill=ACCENT,width=2)
            text(dr,(xx-16,880),f"{st*100:.0f}",16,ACCENT)
        dr.line((100,860,1100,860),fill=ACCENT,width=2)
        text(dr,(390,916),f"OVERALL LENGTH {L:g} WORLD UNITS",22,ACCENT)
        # Far mounts have a separate dashed register at their real stations.
        # This avoids suggesting visibility through the solid hull.
        text(dr,(90,1010),"FAR GUN REGISTER (dashed; hidden in solid profile)",17)
        register_labels=[]
        for f in data["features"]:
            if f["offset"]<0 and f["kind"].endswith("gun"):
                c=point(f,params); x,y=project(c,view)
                dashed(dr,(x,1025),(x,1065))
                ly=1068
                if any(abs(x-px)<28 and abs(ly-py)<20 for px,py in register_labels):ly=1091
                register_labels.append((x,ly));text(dr,(x-15,ly),f["id"],17,ACCENT)
                for part in model.parts:
                    if part["feature"]==f["id"] and "_barrel" in part["name"]:
                        n=len(part["v"])//2
                        a,b=project(part["v"][:n].mean(0),view),project(part["v"][n:].mean(0),view)
                        dashed(dr,a,b,fill=(190,185,175));text(dr,(a[0],a[1]-19),f["id"],14)
        hull=next(q for q in model.parts if q["name"]=="M01_hull_envelope")
        deck=next(q for q in model.parts if q["name"]=="M02_foredeck")
        overhang=(hull["v"][:,0].max()-deck["v"][:,0].max())*L
        text(dr,(110,948),f"Hull prow to foredeck edge: {overhang:.3f} units overhang",18)
    if view in ("side","top"):
        hull=next(q for q in model.parts if q["name"]=="M01_hull_envelope")
        for j in ([4] if view=="side" else [4,5]):
            dr.line([project(c,view) for c in hull["v"][j::8]],fill=(184,157,120),width=2)
        text(dr,(340,976) if view=="side" else (550,1140),"Thin tan line: continuous hull deck edge",16)
    if view=="top":
        width,station,lo,hi=beam;y=100+1000*station;x0=600-1000*hi;x1=600-1000*lo
        dr.line((x0,y,x1,y),fill=ACCENT,width=2)
        for x in (x0,x1):dr.line((x,y-8,x,y+8),fill=ACCENT,width=2)
        text(dr,(500,1080),f"Max section beam {width*L:.3f} u @ {station*100:.1f}%",17,ACCENT)
    if view in ("side","top","underside"):
        width=5*1000/L; x0=130; yy=1155
        for i in range(5):
            dr.rectangle((x0+i*width/5,yy,x0+(i+1)*width/5,yy+12),fill=WHITE if i%2==0 else (95,95,95),outline=WHITE)
        text(dr,(x0,yy-28),"5 WORLD UNITS",18)
    # Labels are a register, not marks painted onto a fitting. Near and far
    # callouts are separated to keep the underlying measurement render clear.
    if view in ("top","underside"):
        used=[]
        for f in sorted(data["features"],key=lambda f:f["station"]):
            c=point(f,params); x,y=project(c,view); labelx=1080 if x>600 else 110
            labely=y
            for px,py in used:
                if abs(labelx-px)<50 and abs(labely-py)<23:labely=py+25
            used.append((labelx,labely)); dr.line((x,y,labelx,labely),fill=(155,150,140),width=1)
            dr.ellipse((x-3,y-3,x+3,y+3),outline=ACCENT,width=2)
            text(dr,(labelx+4,labely-11),f["id"],18,ACCENT)
    if view=="underside":
        text(dr,(340,1095),"BELLY CLOSURE: TO BE DESIGNED",19,ACCENT)
    if view=="stern":
        text(dr,(180,1000),"HIDDEN EXIT / PLUMBING: TO BE DESIGNED",22,ACCENT)
    im.save(p/(view+".png")); return im


def update_table(p,data):
    from build_sheets_532_geometry import Model
    params=json.loads((p/"parameters.json").read_text()); src=DEST/data["code"]/"feature_table.md"
    model=Model(data,params).build()
    lines=src.read_text().splitlines(); byid={f["id"]:f for f in data["features"]}
    for i,line in enumerate(lines):
        if not line.startswith("| "):continue
        cells=[s.strip() for s in line.split("|")[1:-1]]
        if cells[0] not in byid:continue
        f=byid[cells[0]]; c=point(f,params)*data["length"]
        if f["kind"]=="chain":
            chain=[q for q in model.parts if q["feature"]==f["id"]]
            chosen=min(chain,key=lambda q:abs(q["v"][:,0].mean()-c[0]/data["length"]))
            c=chosen["v"].mean(0)*data["length"]
        cells[3]=f"{(.5-c[0]/data['length'])*100:.1f}"
        cells[4]=f"{c[1]:+.3f}"; cells[5]=f"{c[2]:+.3f}"
        # Recompute aim using a differential through the final loft transform.
        f2=dict(f); a=np.array(f["aim"]); f2["station"]-=a[0]*.0001; f2["offset"]+=a[1]*.0001; f2["height"]+=a[2]*.0001
        aim=point(f2,params)-point(f,params); aim/=np.linalg.norm(aim)
        cells[6]=",".join(f"{x:+.3f}" for x in aim)
        lines[i]="| "+" | ".join(cells)+" |"
    lines += ["", "## Final loft fit", "", "Offsets and heights above include the final seven-section loft fit. "
              "The reproducible section coefficients and fitted concept camera are in `fit_parameters.json` and "
              "`concept_camera.json`. The JSON placement source is in normalized pre-fit coordinates. "
              "Use the coefficients when rebuilding it, or work directly from the .blend.", ""]
    lines += ["Engine, intake and claw braces are neutral mounting placeholders, TO BE DESIGNED. "
              "Chains follow the actual upper surface; their tabulated height is at mid-run. "
              "No hidden engine mouth or far weapon has been approved by adding these mounts.", "",
              "## Major masses and colour zones", "", "These are blockout masses, one of each named row. "
              "Bounds include the final section fit. Paint is schematic; use the accepted beauty for finish.", "",
              "| Mass | Count | Station % range | Offset range units | Height range units | Role / colour |",
              "|---|---:|---|---|---|---|"]
    for part in model.parts:
        if part["feature"] is not None:continue
        v=part["v"]*data["length"];lo=v.min(0);hi=v.max(0)
        lines.append(f"| {part['name']} | 1 | {(0.5-hi[0]/data['length'])*100:.1f} to {(0.5-lo[0]/data['length'])*100:.1f} | "
                     f"{lo[1]:+.3f} to {hi[1]:+.3f} | {lo[2]:+.3f} to {hi[2]:+.3f} | {part['mat']} |")
    src.write_text("\n".join(lines),encoding="ascii")


def sheets(root):
    from build_sheets_532_geometry import Model
    for code in ("corsair_A16","corsair_A17"):
        p=root/code; out=DEST/code; data=json.loads((p/"inputs.json").read_text()); L=data["length"]
        params=json.loads((p/"parameters.json").read_text()); T=Model(data,params).build().triangles()
        extent=np.ptp(T.reshape(-1,3),axis=0)*L
        score=json.loads((p/"silhouette_scores.json").read_text())[code]["overlap"]
        views={v:annotate(p,data,v) for v in ("side","top","underside","bow","stern")}
        sheet=Image.new("RGB",(3600,2700),GREY); dr=ImageDraw.Draw(sheet)
        text(dr,(44,24),code+" | "+data["name"].upper(),48)
        text(dr,(44,89),f"ASHFALL HULLBREAKERS / {data['cls'].upper()} / BUILD SHEET v1 / 2026-11-11",25)
        status="OUTLINE PASS" if score>=90 else "OUTLINE FAIL: REVISION REQUIRED"
        text(dr,(44,132),f"{L:g} world units | one 3D blockout | side/top/belly {1000/L:.5f} px/unit | {score:.1f}% IoU | {status}",23,ACCENT)
        # Measurement views are pasted at exactly 1:1. Empty margins are cropped
        # from side and end views; their geometry is never rescaled.
        sheet.paste(views["side"].crop((0,300,1200,1200)),(0,205))
        sheet.paste(views["top"],(1200,205)); sheet.paste(views["underside"],(2400,205))
        for xx in (1200,2400):dr.line((xx,205,xx,2590),fill=(90,86,80),width=2)
        beauty=Image.open(data["beauty"]).convert("RGB"); beauty.thumbnail((1140,760))
        sheet.paste(beauty,(30,1170)); text(dr,(35,1130),code+" / ACCEPTED BEAUTY / IDENTITY, NOT A RULER",22,ACCENT)
        q=flat(p/"three_quarter_raw.png").crop((0,220,1200,1040))
        sheet.paste(q,(0,1900)); text(dr,(35,1904),code+" / BLOCKOUT / 45 DEG PORT, 30 DEG UP",22)
        sheet.paste(views["bow"].crop((0,230,1200,1000)),(1200,1470))
        sheet.paste(views["stern"].crop((0,230,1200,1050)),(2400,1470))
        text(dr,(1250,1430),code+" / BOW-ON",26,ACCENT)
        text(dr,(2450,1430),code+" / ENGINE-END INSET",26,ACCENT)
        summary=collections.Counter(f["kind"] for f in data["features"])
        text(dr,(1250,2310),"FEATURE REGISTER / FULL TABLE ATTACHED",26,ACCENT)
        for i,(kind,count) in enumerate(summary.items()):
            text(dr,(1250+(i//5)*530,2360+(i%5)*35),f"{kind.replace('_',' ')}: {count}",22)
        text(dr,(2450,2335),"OPEN DESIGN (shown as plain grey closure):",24,ACCENT)
        for i,s in enumerate(["Belly fittings and internal structure", "Hidden starboard lower weapons", "Far engine exits and aft plumbing", "Chain returns and claw actuators", "Neutral braces are mounting placeholders"]):
            text(dr,(2450,2380+i*36),"TO BE DESIGNED: "+s,20)
        text(dr,(1250,2600),f"Envelope: L {extent[0]:.3f} / B {extent[1]:.3f} / H {extent[2]:.3f} world units",22)
        beam=section_beam(T)
        text(dr,(1250,2630),f"Max section beam {beam[0]*L:.3f} units at station {beam[1]*100:.1f}% (includes fittings)",18)
        text(dr,(44,2650),"Refs: accepted round 8 beauty + round 1 original | standard.md, issue 398 | feature_table.md | neutral renders retained",22)
        sheet.save(out/"sheet.jpg",quality=93,subsampling=0); sheet.save(root/(code+"_sheet.jpg"),quality=93,subsampling=0)
        preview=sheet.copy(); preview.thumbnail((960,720)); preview.save(root/(code+"_preview.jpg"),quality=94)
        preview.save(out/"preview.jpg",quality=94)
        # Extra overview makes the beauty/model fit reviewable at chat size.
        comp=Image.new("RGB",(2048,1150),GREY)
        a=Image.open(p/"concept_square.png").convert("RGBA"); b=Image.new("RGBA",a.size,GREY+(255,));b.alpha_composite(a)
        comp.paste(b.convert("RGB"),(0,90)); comp.paste(flat(p/"fitted_camera_raw.png"),(1024,90))
        cd=ImageDraw.Draw(comp); text(cd,(24,24),code+" / ACCEPTED BEAUTY CUTOUT",28); text(cd,(1048,24),code+f" / FITTED BLOCKOUT / {score:.1f}% IoU",28)
        comp.thumbnail((1280,720));comp.save(root/(code+"_fit_compare.jpg"),quality=94)
        for v in views:
            shutil.copy2(p/(v+".png"),out/(v+".png"))
        shutil.copy2(p/"render_manifest.json",out/"render_manifest.json")
        shutil.copy2(p/"parameters.json",out/"fit_parameters.json")
        shutil.copy2(p/"concept_camera.json",out/"concept_camera.json")
        shutil.copy2(p/"silhouette_scores.json",out/"silhouette_scores.json")
        for name in ("gun_inventory.jpg","gun_inventory_pixels.json","shape_reference_measurements.json"):
            if (p/name).exists():shutil.copy2(p/name,out/name)
        q2=flat(p/"three_quarter_raw.png"); d=ImageDraw.Draw(q2);text(d,(25,25),code+" / BLOCKOUT IDENTITY",28);q2.save(out/"three_quarter.png")
        update_table(p,data)
        print("SHEET",code,extent.tolist(),"outline",score,flush=True)


def dress(root):
    # A pilot only. Stop rollout as soon as a structural/count failure appears.
    # qwen_prompt supplies the installed model/Lightning graph. Two explicit
    # image guides supply structure and edges; beauty is the style image.
    sys.path.insert(0,str(REPO/"tools/pc")); import comfy_run as comfy
    comfy.VT=tempfile.gettempdir(); comfy.LOG=str(Path(tempfile.gettempdir())/"issue532_comfy.log")
    comfy.URL="http://127.0.0.1:8189"
    import subprocess,time,urllib.request
    denoise=float(os.environ.get("SHEET_DENOISE",".25"))
    work=root/("style_trial_strong" if denoise>.5 else "style_trial");work.mkdir(exist_ok=True)
    code="corsair_A16"; p=root/code
    src=flat(p/"top_raw.png"); src.resize((1024,1024)).save(work/"structure.png")
    edge=src.convert("L").filter(ImageFilter.FIND_EDGES);edge.resize((1024,1024)).save(work/"edges.png")
    Image.open(REPO/"contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg").save(work/"style.jpg")
    prompt=("Image 1 is the exact orthographic spaceship geometry. Image 2 is ONLY a material reference. "
            "Image 3 is the locked structural edge guide for Image 1. Keep every outline, barrel, dish, "
            "intake and rocket tube exactly at its existing pixel coordinates. Keep this a true overhead "
            "view, bow at top. Add only rusty steel plate texture and wear from Image 2 to Image 1. "
            "Do not add, remove, duplicate, turn, enlarge, simplify or move any object. No perspective. "
            "No engine glow. Flat dark grey background. No text.")
    api=comfy.qwen_prompt("structure.png",prompt,532,"trial",steps=8,cfg=1,lightning=True,angle_w=0,full=True)
    del api["4"];api["5"]["inputs"]["model"]=["3",0]
    api["20"]={"class_type":"LoadImage","inputs":{"image":"style.jpg"}}
    api["21"]={"class_type":"LoadImage","inputs":{"image":"edges.png"}}
    for n in ("10","11"):
        api[n]["inputs"]["image2"]=["20",0];api[n]["inputs"]["image3"]=["21",0]
    api["15"]["inputs"]["denoise"]=denoise
    (work/"workflow.json").write_text(json.dumps(api,indent=2))
    settings=dict(model="qwen_image_edit_2511_fp8mixed.safetensors",lora="Qwen-Image-Edit-2511-Lightning-8steps-V1.0-bf16.safetensors",
                  steps=8,cfg=1,seed=532,denoise=denoise,sampler="euler",scheduler="simple",
                  guides="Image 1: Blender orthographic render, Image 3: fixed image-space edge guide",
                  style="Image 2: accepted corsair_A16 beauty",controlnet="No ControlNet weights installed; multi-reference guidance pilot only",
                  structural_lock="Unproven. Pixel comparison and feature review required before acceptance")
    (work/"settings.json").write_text(json.dumps(settings,indent=2))
    log=open(Path(tempfile.gettempdir())/"issue532_comfy_server.log","a",encoding="utf-8")
    server=subprocess.Popen([str(Path(comfy.R)/"python_embeded/python.exe"),"-s",str(Path(comfy.C)/"main.py"),
                             "--windows-standalone-build","--listen","127.0.0.1","--port","8189",
                             "--output-directory",str(work),"--input-directory",str(work),"--disable-auto-launch"],cwd=comfy.C,stdout=log,stderr=subprocess.STDOUT)
    try:
        for _ in range(120):
            if server.poll() is not None: raise RuntimeError("ComfyUI exited; see TEMP issue532_comfy_server.log")
            try:comfy.get("/system_stats");break
            except Exception:time.sleep(1)
        result=comfy.run(api,"issue532 structure/style pilot",timeout=1200)
        if result is None or result.get("status",{}).get("status_str")!="success":raise RuntimeError("Style pilot failed")
        (work/"history.json").write_text(json.dumps(result,indent=2))
        print("DRESS PILOT DONE",flush=True)
    finally:
        server.terminate();server.wait(30);log.close()


def check(root):
    from build_sheets_532_geometry import Model,barrel_hits
    import silhouette4 as sil
    results={}
    for code in ("corsair_A16","corsair_A17"):
        p=root/code; data=json.loads((p/"inputs.json").read_text()); params=json.loads((p/"parameters.json").read_text())
        model=Model(data,params).build(); T=model.triangles(); L=data["length"]
        manifest=json.loads((p/"render_manifest.json").read_text()); scores=json.loads((p/"silhouette_scores.json").read_text())
        extent=np.ptp(T.reshape(-1,3),axis=0)*L
        errors=[]
        intersections=barrel_hits(model)
        if intersections:errors.append("Barrel intersects another part: "+str(intersections))
        if abs(extent[0]/L-1)>.02:errors.append("Overall model length differs from class length by over 2 percent")
        ppw=[v["pixels_per_world"] for v in manifest["views"].values()]
        if max(ppw)-min(ppw)>1e-6:errors.append("View scales differ")
        if any(v["type"]!="ORTHO" for v in manifest["views"].values()):errors.append("Measurement view not orthographic")
        for f in data["features"]:
            parts=[q for q in model.parts if q["feature"]==f["id"]]
            if not parts:errors.append("No geometry for "+f["id"])
            if f["kind"].endswith("gun") and f["aim"][0]<0:errors.append("Aft gun "+f["id"])
            expected=2 if f["kind"]=="twin_gun" else 1
            if f["kind"].endswith("gun") and sum("_barrel" in q["name"] for q in parts)!=expected:errors.append("Barrel count "+f["id"])
        cam=json.loads((p/"concept_camera.json").read_text())["camera"]
        raw_iou=sil.iou(sil.raster(T,cam),sil.concept_mask(p/"concept_square.png"))
        if raw_iou<.90:errors.append("Unrounded outline below 90 percent")
        pixel_lengths={}
        for view in ("side","top","underside","bow","stern"):
            alpha=np.asarray(Image.open(p/(view+"_raw.png")).convert("RGBA"))[:,:,3]>128
            yy,xx=np.nonzero(alpha)
            if xx.min()<=0 or yy.min()<=0 or xx.max()>=1199 or yy.max()>=1199:errors.append("Cropped render "+view)
            if view in ("side","top"):
                pixel_lengths[view]=int(np.ptp(xx if view=="side" else yy)+1)
        pixel_error=abs(pixel_lengths["side"]-pixel_lengths["top"])/1000*100
        if pixel_error>2:errors.append("Rendered side/top lengths disagree by more than 2 percent")
        for view,px in pixel_lengths.items():
            if abs(px-1000)>20:errors.append("Rendered "+view+" length differs from scale")
        result=dict(code=code,result="PASS" if not errors else "FAIL",errors=errors,
                    length_from_game=L,model_length=round(float(extent[0]),5),length_error_percent=round(abs(float(extent[0])/L-1)*100,4),
                    scale_difference_percent=0,rendered_length_pixels=pixel_lengths,rendered_length_difference_percent=pixel_error,
                    features=len(data["features"]),outline=scores[code],
                    outline_unrounded_percent=raw_iou*100,
                    barrel_intersections=intersections,
                    limitations="Geometry consistency check only. Beauty identity, small fitting counts and open design still require visual review")
        results[code]=result;(DEST/code/"checks.json").write_text(json.dumps(result,indent=2)+"\n")
        print(json.dumps(result),flush=True)
    (root/"checks.json").write_text(json.dumps(results,indent=2))
    if any(v["errors"] for v in results.values()):sys.exit(1)


def restore(root):
    from build_sheets_532_geometry import Model
    import silhouette4 as sil
    for code in ("corsair_A16","corsair_A17"):
        p=root/code;source=DEST/code
        shutil.copy2(source/"fit_parameters.json",p/"parameters.json")
        shutil.copy2(source/"concept_camera.json",p/"concept_camera.json")
        # Recreate the square gate canvas without changing image aspect.
        im=Image.open(p/"concept_cut.png").convert("RGBA");sq=Image.new("RGBA",(1920,1920));sq.alpha_composite(im,(0,320))
        sq.resize((1024,1024),Image.Resampling.LANCZOS).save(p/"concept_square.png")
        data=json.loads((p/"inputs.json").read_text());params=json.loads((p/"parameters.json").read_text())
        np.savez_compressed(p/"blockout_fitted.npz",tris=Model(data,params).build().triangles())
        sil.score(str(p/"concept_square.png"),str(p/"concept_camera.json"),str(p),[code+"="+str(p/"blockout_fitted.npz")])


def dispatch(cmd,root):
    if cmd=="sheets":sheets(root)
    elif cmd=="dress":dress(root)
    elif cmd=="check":check(root)
    elif cmd=="restore":restore(root)
    else:raise ValueError(cmd)
