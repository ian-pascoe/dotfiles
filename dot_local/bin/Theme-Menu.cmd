@echo off
rem Hands a request to the theme menu of YASB's theme widget (Theme-Menu.ps1) through its pipe: "menu" (the default),
rem "toggle-mode" or "quit". The menu keeps running, so it opens at once; only when nothing listens on the pipe does
rem this start Theme-Menu.ps1, which takes a few seconds. Its handles go to nul so that it holds none of the caller's.
setlocal
set "request=%~1"
if not defined request set "request=menu"
(>\\.\pipe\ThemeMenu echo %request%) 2>nul && exit /b 0
start "" /b pwsh -NoProfile -NonInteractive -File "%~dp0Theme-Menu.ps1" -Request %request% <nul >nul 2>&1
