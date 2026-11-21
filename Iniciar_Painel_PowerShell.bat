@echo off
title Iniciando CyberDeck OS (PowerShell)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Painel_Manutencao_PC.ps1"
if %errorlevel% neq 0 pause
