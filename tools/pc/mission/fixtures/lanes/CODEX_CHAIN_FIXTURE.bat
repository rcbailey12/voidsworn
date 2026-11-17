@echo off
for %%N in (918 920 921) do call :one %%N
goto :eof
:one
call "%V%\build_b\tools\pc\codex_issue.bat" %1
