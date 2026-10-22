@echo off
set L=..\smoke_log.txt
echo --- v14g: AI hulls lit by stored normals (one-sided) --- >> %L%
"%PYEXE%" build.py test >> %L% 2>&1
if not exist shots_v56g mkdir shots_v56g
set OUT=shots_v56g
set TPLS=c_boss
set MAP=belt
set ZOOM=1.0,0.5
set TAG=belt
set "EVAL=(()=>{const S=G.scene; const out={}; for(const m of S.meshes){ if(!m.isEnabled()||!/hull_(ai|kit)$/.test(m.name)) continue; const wm=m.getWorldMatrix(); const P=m.getVerticesData('position'), N=m.getVerticesData('normal'); const info={det:+wm.determinant().toExponential(2),side:m.sideOrientation,ovr:m.overrideMaterialSideOrientation,bfc:m.material.backFaceCulling,tsl:m.material.twoSidedLighting,mat:m.material.name}; if(!P||!N){info.nodata=true; out[m.name]=info; continue;} const c=m.getBoundingInfo().boundingBox.centerWorld; let pos=0,neg=0; const v=new BABYLON.Vector3(), n=new BABYLON.Vector3(); for(let i=0;i<P.length/3;i+=7){ BABYLON.Vector3.TransformCoordinatesFromFloatsToRef(P[i*3],P[i*3+1],P[i*3+2],wm,v); BABYLON.Vector3.TransformNormalFromFloatsToRef(N[i*3],N[i*3+1],N[i*3+2],wm,n); if(BABYLON.Vector3.Dot(n,v.subtract(c))>0) pos++; else neg++; } info.out=pos; info.in=neg; const I=m.getIndices(); let wo=0,wi=0; const a=new BABYLON.Vector3(),b=new BABYLON.Vector3(),d=new BABYLON.Vector3(); for(let t=0;t<I.length/3;t+=11){ const i0=I[t*3],i1=I[t*3+1],i2=I[t*3+2]; BABYLON.Vector3.FromArrayToRef(P,i0*3,a); BABYLON.Vector3.FromArrayToRef(P,i1*3,b); BABYLON.Vector3.FromArrayToRef(P,i2*3,d); const g=BABYLON.Vector3.Cross(b.subtract(a),d.subtract(a)); const nn=new BABYLON.Vector3(N[i0*3],N[i0*3+1],N[i0*3+2]); if(BABYLON.Vector3.Dot(g,nn)>0) wo++; else wi++; } info.windAgree=wo; info.windDisagree=wi; out[m.name]=info; } const L=S.lights.filter(l=>l.isEnabled()).map(l=>[l.name,l.getClassName(),l.direction?l.direction.asArray().map(x=>+x.toFixed(2)):null,+l.intensity.toFixed(2)]); return JSON.stringify({out,L,useRH:S.useRightHandedSystem}); })()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set EVAL=
set ONLY=desk
set ZOOM=1.0
set MAP=planet
set TAG=planet
"%PYEXE%" closeshot.py >> %L% 2>&1
set MAP=belt
set TPLS=warden,h_dominion,c_hulk,i_boss
set TAG=fleet
"%PYEXE%" closeshot.py >> %L% 2>&1
set ONLY=
set MAP=
set OUT=
set TAG=
set TPLS=
set ZOOM=
echo --- v14g done --- >> %L%
cd /d "%~dp0"
