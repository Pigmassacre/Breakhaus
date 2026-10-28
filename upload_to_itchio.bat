@echo off
cd /d "%~dp0"
python upload_to_itchio.py %*
exit /b %ERRORLEVEL%
