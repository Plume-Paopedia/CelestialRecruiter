@echo off
echo ============================================
echo  CelestialRecruiter AI Companion
echo  Powered by Claude (Anthropic)
echo ============================================
echo.

cd /d "%~dp0"

:: Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found. Install Python 3.10+ from python.org
    pause
    exit /b 1
)

:: Check anthropic library
python -c "import anthropic" >nul 2>&1
if errorlevel 1 (
    echo Installing dependencies...
    pip install anthropic watchdog
    echo.
)

:: Check config
if not exist config.json (
    echo ERROR: config.json not found!
    echo Copy config.example.json to config.json and fill in your settings.
    echo Required: anthropic_api_key, savedvariables_path
    pause
    exit /b 1
)

echo Starting AI Recruiter...
echo Press Ctrl+C to stop.
echo.
python ai_recruiter.py --config config.json

pause
