@echo off
REM Wrapper script to run im.sh from anywhere on Windows
set "ORIGINAL_DIR=%CD%"
cd /d "%~dp0"
setlocal
set WSLENV=GH_TOKEN/u:ORIGINAL_DIR/p:GBIF_USER:GBIF_PWD
wsl bash im.sh "%ORIGINAL_DIR%" %*
