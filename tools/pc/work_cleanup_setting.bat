@echo off
rem WORKHORSE_CLEANUP.bat (issue 377, Opus, Nov 12 2026; retired by issue 1186, Nov 20 2026).
rem Workhorse runs now share one reused checkout per arm (work217\slot_<arm>\repo), so there is no per-run copy to remove
rem and the old remove_repo_copy_after_push switch does nothing. This file changes nothing, so an old shortcut cannot
rem overwrite runner_settings.txt (which also holds the free-space floors and the OpenAI budget).
setlocal
title Workhorse cleanup switch (retired)
echo.
echo  This switch is no longer needed. Each workhorse arm now reuses one copy of the game's code,
echo  so runs no longer leave a new copy behind. Nothing was changed.
echo.
pause
exit /b 0
