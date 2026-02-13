@echo off
REM CelestialRecruiter Discord Webhook Bot Launcher
REM This script starts the Discord webhook companion

echo ========================================
echo CelestialRecruiter Discord Bot
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.7+ from https://www.python.org/
    echo.
    pause
    exit /b 1
)

echo Python found:
python --version
echo.

REM Check if config.json exists
if not exist "config.json" (
    echo WARNING: config.json not found
    echo.
    echo Creating default config.json template...
    python discord_webhook.py --create-config
    echo.
    echo Please edit config.json with your settings:
    echo   1. Set your SavedVariables path
    echo   2. Set your Discord webhook URL
    echo.
    echo Then run this script again.
    echo.
    pause
    exit /b 0
)

REM Check if dependencies are installed
echo Checking dependencies...
python -c "import requests" >nul 2>&1
if errorlevel 1 (
    echo Installing required dependencies...
    pip install requests watchdog
    echo.
)

REM Start the bot
echo Starting Discord webhook bot...
echo Press Ctrl+C to stop
echo.
python discord_webhook.py

pause
