@echo off
cd /d "%~dp0"
python build_game.py %*
exit /b %ERRORLEVEL%
