@echo off
set L=..\smoke_log.txt
echo --- v13k: inside-out audit of every mesh (before/after faceOut) --- >> %L%
"%PYEXE%" build.py test >> %L% 2>&1
if not exist shots_v55p mkdir shots_v55p
set OUT=shots_v55p
set ONLY=desk
set ZOOM=1.0
set TPLS=c_boss,h_dominion,i_boss,b_boss,d_boss,warden,c_hulk
set "EVAL=(()=>{try{objProto('obj|station',46);objProto('obj|transport',10);objProto('obj|beacon',8);}catch(e){} const S=G.scene, R={}; for(const m of S.meshes){ let P,N,I; try{P=m.getVerticesData('position');N=m.getVerticesData('normal');I=m.getIndices();}catch(e){continue} if(!P||!N||!I||I.length<30) continue; const det=m.computeWorldMatrix(true).determinant(); let w=0,a=0; for(let t=0;t<I.length;t+=3*Math.max(1,Math.floor(I.length/3/400))){ const A=I[t]*3,B=I[t+1]*3,C=I[t+2]*3, ux=P[B]-P[A],uy=P[B+1]-P[A+1],uz=P[B+2]-P[A+2],vx=P[C]-P[A],vy=P[C+1]-P[A+1],vz=P[C+2]-P[A+2]; const d=((uy*vz-uz*vy)*(N[A]+N[B]+N[C])+(uz*vx-ux*vz)*(N[A+1]+N[B+1]+N[C+1])+(ux*vy-uy*vx)*(N[A+2]+N[B+2]+N[C+2]))*(det<0?-1:1); if(d!==0){a++; if(d>0) w++;} } if(!a) continue; const k=m.name.replace(/^(ship\.|fore\.|aft\.)+/,'').replace(/[0-9_|]+$/,'')+(m.material?' ['+(m.material.twoSidedLighting?'2s':'1s')+(m.material.backFaceCulling?',cull':'')+']':''); const r=R[k]||(R[k]={n:0,bad:0,mixed:0}); r.n++; const f=w/a; if(f>.6) r.bad++; else if(f>.25) r.mixed++; } const out=Object.entries(R).filter(([k,r])=>r.bad||r.mixed).map(([k,r])=>k+' n'+r.n+' bad'+r.bad+' mixed'+r.mixed); return out.join(' ; ')+' || total kinds '+Object.keys(R).length; })()"
for %%M in (belt planet storm) do (
  set MAP=%%M
  set TAG=after_%%M
  "%PYEXE%" closeshot.py >> %L% 2>&1
)
set PRE=G.diagNoFaceOut=true
set MAP=belt
set TAG=before_belt
"%PYEXE%" closeshot.py >> %L% 2>&1
set PRE=
set EVAL=
set ONLY=
set MAP=
set OUT=
set TAG=
set TPLS=
set ZOOM=
echo --- v13k done --- >> %L%
cd /d "%~dp0"
