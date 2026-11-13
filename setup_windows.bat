@echo off
setlocal
cd /d "%~dp0"
title SONIQ - Preparacao Flutter

set "FLUTTER=flutter"
where flutter >nul 2>nul
if errorlevel 1 (
  if exist "C:\src\flutter\bin\flutter.bat" (
    set "FLUTTER=C:\src\flutter\bin\flutter.bat"
  ) else (
    echo [ERRO] Flutter nao encontrado. Instale o Flutter ou adicione-o ao PATH.
    pause
    exit /b 1
  )
)

echo.
echo ======================================
echo    SONIQ 1.0.0 BETA - CONFIGURACAO
echo ======================================
echo.

if not exist "android\settings.gradle" if not exist "android\settings.gradle.kts" (
  echo [1/4] Gerando estrutura Android compativel com seu Flutter...
  call "%FLUTTER%" create --platforms=android --org com.soniq --project-name soniq .
  if errorlevel 1 goto :fail
) else (
  echo [1/4] Estrutura Android ja existe.
)

echo [2/4] Instalando dependencias...
call "%FLUTTER%" pub get
if errorlevel 1 goto :fail

echo [3/4] Aplicando o nome SONIQ no Android...
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\prepare_android.ps1"
if errorlevel 1 goto :fail

echo [4/4] Gerando icone personalizado...
call "%FLUTTER%" pub run flutter_launcher_icons
if errorlevel 1 goto :fail

echo.
echo ======================================
echo   PRONTO! Execute: flutter run
echo ======================================
echo.
pause
exit /b 0

:fail
echo.
echo [ERRO] A preparacao nao foi concluida. Veja a mensagem acima.
pause
exit /b 1
