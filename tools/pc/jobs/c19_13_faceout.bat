@echo off
set L=..\smoke_log.txt
echo --- v13j: hull winding fix (faceOut), before/after --- >> %L%
"%PYEXE%" build.py test >> %L% 2>&1
if not exist shots_v55o mkdir shots_v55o
set OUT=shots_v55o
set MAP=belt
set TPLS=c_boss
set ZOOM=1.0,0.5
set TAG=after
"%PYEXE%" closeshot.py >> %L% 2>&1
set ONLY=desk
set ZOOM=1.0
set TPLS=warden,h_dominion,c_hulk,i_boss
set TAG=after
"%PYEXE%" closeshot.py >> %L% 2>&1
set PRE=G.diagNoFaceOut=true
set TAG=before
"%PYEXE%" closeshot.py >> %L% 2>&1
set PRE=
set ONLY=
set MAP=
set OUT=
set TAG=
set TPLS=
set ZOOM=
echo --- v13j done --- >> %L%
cd /d "%~dp0"
