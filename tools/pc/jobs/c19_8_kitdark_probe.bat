@echo off
set L=..\smoke_log.txt
echo --- v13e: why flank plates read dark in game (phone, 4 variants) --- >> %L%
if not exist shots_v55j mkdir shots_v55j
set OUT=shots_v55j
set TPLS=c_boss
set ZOOM=1.0
set MAP=belt
set ONLY=phone
set TAG=base
set "EVAL=(()=>{const k=G.scene.meshes.filter(m=>m.name==='hull_kit'); return JSON.stringify(k.map(m=>({rs:m.receiveShadows,bfc:m.material.backFaceCulling,tsl:m.material.twoSidedLighting,met:m.material.metallic,ro:m.material.roughness,di:m.material.directIntensity,ei:m.material.environmentIntensity,lvl:m.material.albedoTexture&&m.material.albedoTexture.level,sh:!!G.shadow})))})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set TAG=cull
set "EVAL=(()=>{let n=0; for(const m of G.scene.meshes) if(m.name==='hull_kit'){m.material.backFaceCulling=true;n++} return n})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set TAG=noshad
set "EVAL=(()=>{let n=0; for(const m of G.scene.meshes) if(m.name==='hull_kit'){m.receiveShadows=false;n++} return n})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set TAG=both
set "EVAL=(()=>{let n=0; for(const m of G.scene.meshes) if(m.name==='hull_kit'){m.receiveShadows=false;m.material.backFaceCulling=true;n++} return n})()"
"%PYEXE%" closeshot.py >> %L% 2>&1
set EVAL=
set ONLY=
set MAP=
set OUT=
set TAG=
set TPLS=
set ZOOM=
echo --- v13e done --- >> %L%
cd /d "%~dp0"
