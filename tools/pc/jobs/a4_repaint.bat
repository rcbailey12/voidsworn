@echo off
rem A4 concept paint (feel pass, Nov 1): repaint already built ships with their concept art projected on (tools/blender/a4/concept.py).
rem Only the colour map changes: concept.py rewrites CODE_base.jpg in a4\godot\CODE and a4\godot_hi\CODE (the glb files name that file,
rem so nothing is re-exported) and the normal map's import settings (BC5); this job copies both into the game build. Godot re-imports
rem them on its next --import; godot\gen\ships needs no rebuild (the converted scenes point at the imported textures).
rem Queued from Downloads\voidsworn_test\build: set A4CODES=CODE CODE ..., call a4tools\a4_repaint.bat. Log per ship: a4\out\CODE\concept_log.txt
setlocal enabledelayedexpansion
set PY="%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"
set A4=%USERPROFILE%\Downloads\voidsworn_test\a4
if not exist a4tools\a4\concept.py echo a4: build\a4tools is missing concept.py, copy it in first
if not exist a4tools\a4\concept.py goto done
for %%C in (%A4CODES%) do (
  echo --- a4 concept paint %%C ---
  set "OUT=%A4%\out\%%C"
  if exist "!OUT!\%%C_meta.json" (
    call tools\pc\tmo.bat 900 %PY% -s a4tools\a4\concept.py "!OUT!\%%C_meta.json" --sheet --apply --base "%A4%\godot\%%C" --base "%A4%\godot_hi\%%C" > "!OUT!\concept_log.txt" 2>&1
    type "!OUT!\concept_log.txt" | findstr /l /c:"[concept]" /c:"Error" /c:"Traceback"
    if not exist "%CD%\godot\assets\ships\%%C" mkdir "%CD%\godot\assets\ships\%%C"
    copy /y "%A4%\godot\%%C\%%C_base.jpg" "%CD%\godot\assets\ships\%%C\" > nul
    copy /y "%A4%\godot\%%C\%%C_normal.jpg.import" "%CD%\godot\assets\ships\%%C\" > nul
  ) else (
    echo a4: no build for %%C in !OUT!
  )
)
:done
endlocal
exit /b
