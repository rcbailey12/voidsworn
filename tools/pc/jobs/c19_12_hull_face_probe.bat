@echo off
set L=..\smoke_log.txt
echo --- v13i: is the hull lit from the wrong side (cull test, one-sided lighting test) --- >> %L%
if not exist shots_v55n mkdir shots_v55n
set OUT=shots_v55n
set TPLS=c_boss
set ZOOM=1.0
set MAP=belt
set ONLY=phone
set EVALWAIT=3000
set TAG=hullcull
set "EVAL=(()=>{let n=[]; for(const m of G.scene.meshes) if(m.isEnabled()&&/hull_ai$/.test(m.name)){m.material.backFaceCulling=true; n.push(m.name)} return n.join(',')})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set TAG=hull1side
set "EVAL=(()=>{let n=[]; for(const m of G.scene.meshes) if(m.isEnabled()&&/hull_ai$/.test(m.name)){m.material.twoSidedLighting=false; n.push(m.name)} return n.join(',')})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set TAG=kitcull
set "EVAL=(()=>{let n=[]; for(const m of G.scene.meshes) if(m.isEnabled()&&/hull_kit$/.test(m.name)){m.material.backFaceCulling=true; n.push(m.name)} return n.join(',')})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set EVAL=
set EVALWAIT=
set ONLY=
set MAP=
set OUT=
set TAG=
set TPLS=
set ZOOM=
echo --- v13i done --- >> %L%
cd /d "%~dp0"
