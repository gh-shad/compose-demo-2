@echo off
title Docker Compose Demo
rem Double-click this file to run the whole demo. It runs Start-Demo.ps1 (in the same folder).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Demo.ps1" %*
