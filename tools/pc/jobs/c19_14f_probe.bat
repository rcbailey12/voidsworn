@echo off
set L=..\smoke_log.txt
echo --- v14f: hull one-sided lighting probe --- >> %L%
if not exist shots_v56f mkdir shots_v56f
set OUT=shots_v56f
set TPLS=c_boss
set ZOOM=1.0
set MAP=belt
set ONLY=phone
set EVALWAIT=3000
set TAG=hull1s
set "EVAL=(()=>{let n=[]; for(const m of G.scene.meshes) if(m.isEnabled()&&/hull_ai$/.test(m.name)){m.material.twoSidedLighting=false; n.push(m.name+':'+m.material.name)} return n.join(',')})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set TAG=kit2s
set "EVAL=(()=>{let n=[]; for(const m of G.scene.meshes) if(m.isEnabled()&&/hull_kit$/.test(m.name)){m.material.twoSidedLighting=true; n.push(m.name)} return n.join(',')})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set TAG=cullboth
set "EVAL=(()=>{let n=[]; for(const m of G.scene.meshes) if(m.isEnabled()&&/hull_(ai|kit)$/.test(m.name)){m.material.backFaceCulling=true; n.push(m.name)} return n.join(',')})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set EVAL=
set EVALWAIT=
set ONLY=
set MAP=
set OUT=
set TAG=
set TPLS=
set ZOOM=
echo --- v14f done --- >> %L%
cd /d "%~dp0"
