@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0next-object.ps1" %*
