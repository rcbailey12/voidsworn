@echo off
set L=..\smoke_log.txt
echo --- v13f: kit darkness probe 2 (flat colour / unlit / no HullFx) --- >> %L%
if not exist shots_v55k mkdir shots_v55k
set OUT=shots_v55k
set TPLS=c_boss
set ZOOM=1.0
set MAP=belt
set ONLY=phone
set TAG=flat
set "EVAL=(()=>{let n=0; for(const m of G.scene.meshes) if(m.name==='hull_kit'){const k=m.material.clone('kprobe'); k.albedoTexture=null; k.albedoColor=new BABYLON.Color3(.5,.1,.07); m.material=k; n++} return n})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set TAG=unlit
set "EVAL=(()=>{let n=0; for(const m of G.scene.meshes) if(m.name==='hull_kit'){m.material.unlit=true; n++} return n})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set TAG=nofx
set "EVAL=(()=>{let n=0; for(const m of G.scene.meshes) if(m.name==='hull_kit'){const p=m.material.pluginManager&&m.material.pluginManager.getPlugin('HullFx'); if(p){p.isEnabled=false; n++}} return n})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set EVAL=
set ONLY=
set MAP=
set OUT=
set TAG=
set TPLS=
set ZOOM=
echo --- v13f done --- >> %L%
cd /d "%~dp0"
