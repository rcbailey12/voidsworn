@echo off
set L=..\smoke_log.txt
echo --- v13g: kit darkness probe 3 (which mesh are the dark plates) --- >> %L%
if not exist shots_v55l mkdir shots_v55l
set OUT=shots_v55l
set TPLS=c_boss
set ZOOM=1.0
set MAP=belt
set ONLY=phone
set EVALWAIT=3000
set TAG=list
set "EVAL=JSON.stringify(G.scene.meshes.filter(m=>/kit|hull/i.test(m.name)).map(m=>[m.name,m.isEnabled(),m.isVisible,m.material&&m.material.name,m.getTotalVertices(),m.getTotalIndices()/3|0]))"
"%PYEXE%" closeshot.py >> %L% 2>&1
set TAG=nokit
set "EVAL=(()=>{let n=[]; for(const m of G.scene.meshes) if(/kit/i.test(m.name)){m.setEnabled(false); n.push(m.name)} return n.join(',')})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set TAG=flat
set "EVAL=(()=>{let n=[]; const k=new BABYLON.PBRMaterial('kprobe',G.scene); k.albedoColor=new BABYLON.Color3(.5,.1,.07); k.metallic=0; k.roughness=.6; for(const m of G.scene.meshes) if(/kit/i.test(m.name)){m.material=k; n.push(m.name)} return n.join(',')})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set EVAL=
set EVALWAIT=
set ONLY=
set MAP=
set OUT=
set TAG=
set TPLS=
set ZOOM=
echo --- v13g done --- >> %L%
cd /d "%~dp0"
