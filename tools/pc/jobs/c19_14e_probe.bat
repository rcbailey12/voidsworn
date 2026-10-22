@echo off
set L=..\smoke_log.txt
echo --- v14e: shaded-side plates probe (no finish maps / no bump / unlit kit) --- >> %L%
if not exist shots_v56e mkdir shots_v56e
set OUT=shots_v56e
set TPLS=c_boss
set ZOOM=1.0
set MAP=belt
set ONLY=phone
set PRE=G.noFinish=true
set TAG=nofin
"%PYEXE%" closeshot.py >> %L% 2>&1
set PRE=G.finBump=0
set TAG=nobump
"%PYEXE%" closeshot.py >> %L% 2>&1
set PRE=
set EVALWAIT=3000
set TAG=unlitkit
set "EVAL=(()=>{let n=[]; for(const m of G.scene.meshes) if(m.isEnabled()&&/hull_(kit|ai)$/.test(m.name)){m.material.unlit=true; n.push(m.name)} return n.join(',')})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set EVAL=
set EVALWAIT=
set ONLY=
set MAP=
set OUT=
set TAG=
set TPLS=
set ZOOM=
echo --- v14e done --- >> %L%
cd /d "%~dp0"
