@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

:: ═══════════════════════════════════════════════════════════════
:: CelestialRecruiter - Key Generator
:: ═══════════════════════════════════════════════════════════════

set "SCRIPT_DIR=%~dp0"
set "KEYGEN=%SCRIPT_DIR%keygen.py"

:: ─────────── Defaults (customize here) ───────────
set "DEFAULT_TIER=REC"
set "DEFAULT_DAYS=35"
set "PYTHON=python"

:: ─────────── Colors ───────────
set "HEADER=[93m"
set "GOLD=[33m"
set "GREEN=[32m"
set "RED=[31m"
set "CYAN=[36m"
set "DIM=[90m"
set "RESET=[0m"

:menu
cls
echo.
echo  %GOLD%═══════════════════════════════════════════════%RESET%
echo  %GOLD%   CelestialRecruiter - Key Generator%RESET%
echo  %GOLD%═══════════════════════════════════════════════%RESET%
echo.
echo   %CYAN%[1]%RESET%  Generer une clef unique
echo   %CYAN%[2]%RESET%  Generer plusieurs clefs
echo   %CYAN%[3]%RESET%  Valider une clef existante
echo   %CYAN%[4]%RESET%  Generation batch (CSV)
echo.
echo   %DIM%[0]  Quitter%RESET%
echo.
set "choice="
set /p "choice=  Choix : "

if "%choice%"=="1" goto single
if "%choice%"=="2" goto multi
if "%choice%"=="3" goto validate
if "%choice%"=="4" goto batch
if "%choice%"=="0" goto :eof
goto menu

:: ═══════════════════════════════════════════════════════════════
:ask_player
:: ═══════════════════════════════════════════════════════════════
echo.
echo   %GOLD%Personnage lie (Name-Realm)%RESET%
echo   %DIM%Exemple : Plume-Hyjal%RESET%
echo.
set "player="
set /p "player=  Personnage : "
if "%player%"=="" (
    echo.
    echo   %RED%Le nom du personnage est obligatoire.%RESET%
    goto ask_player
)
goto :eof

:: ═══════════════════════════════════════════════════════════════
:single
:: ═══════════════════════════════════════════════════════════════
cls
echo.
echo  %HEADER%── Generer une clef ──%RESET%
echo.
echo   Tiers disponibles :
echo     %CYAN%REC%RESET%  = Le Recruteur  (3€/mois)
echo     %CYAN%PRO%RESET%  = L'Elite       (7€/mois)
echo     %CYAN%LIFE%RESET% = Le Legendaire (20€ lifetime)
echo.
set "tier="
set /p "tier=  Tier [%DEFAULT_TIER%] : "
if "%tier%"=="" set "tier=%DEFAULT_TIER%"

call :ask_player

if /i "%tier%"=="LIFE" (
    echo.
    echo  %DIM%Lifetime = pas d'expiration%RESET%
    echo.
    %PYTHON% "%KEYGEN%" LIFE --player "!player!"
    goto done
)

echo.
echo   Methode d'expiration :
echo     %CYAN%[1]%RESET%  Nombre de jours (defaut: %DEFAULT_DAYS%)
echo     %CYAN%[2]%RESET%  Date precise (YYYYMMDD)
echo.
set "method="
set /p "method=  Choix [1] : "
if "%method%"=="" set "method=1"

if "%method%"=="2" (
    set "expdate="
    set /p "expdate=  Date d'expiration (YYYYMMDD) : "
    echo.
    %PYTHON% "%KEYGEN%" %tier% !expdate! --player "!player!"
) else (
    set "days="
    set /p "days=  Jours de validite [%DEFAULT_DAYS%] : "
    if "!days!"=="" set "days=%DEFAULT_DAYS%"
    echo.
    %PYTHON% "%KEYGEN%" %tier% --days !days! --player "!player!"
)
goto done

:: ═══════════════════════════════════════════════════════════════
:multi
:: ═══════════════════════════════════════════════════════════════
cls
echo.
echo  %HEADER%── Generer plusieurs clefs ──%RESET%
echo  %DIM%  (chaque clef sera liee au meme personnage)%RESET%
echo.
set "tier="
set /p "tier=  Tier [%DEFAULT_TIER%] : "
if "%tier%"=="" set "tier=%DEFAULT_TIER%"

call :ask_player

set "count="
set /p "count=  Nombre de clefs : "
if "%count%"=="" set "count=1"

set "days="
set /p "days=  Jours de validite [%DEFAULT_DAYS%] : "
if "%days%"=="" set "days=%DEFAULT_DAYS%"

echo.
echo  %DIM%Generation de %count% clef(s) %tier% pour !player!...%RESET%
echo.

if /i "%tier%"=="LIFE" (
    %PYTHON% "%KEYGEN%" LIFE --count %count% --player "!player!"
) else (
    %PYTHON% "%KEYGEN%" %tier% --days %days% --count %count% --player "!player!"
)
goto done

:: ═══════════════════════════════════════════════════════════════
:validate
:: ═══════════════════════════════════════════════════════════════
cls
echo.
echo  %HEADER%── Valider une clef ──%RESET%
echo.
set "key="
set /p "key=  Clef a valider : "

echo.
echo   %DIM%Pour verifier le lien au personnage, entrez son nom.%RESET%
echo   %DIM%Laissez vide pour valider sans personnage.%RESET%
echo.
set "vplayer="
set /p "vplayer=  Personnage (Name-Realm) : "

echo.
if "%vplayer%"=="" (
    %PYTHON% "%KEYGEN%" --validate "%key%"
) else (
    %PYTHON% "%KEYGEN%" --validate "%key%" --validate-player "%vplayer%"
)
goto done

:: ═══════════════════════════════════════════════════════════════
:batch
:: ═══════════════════════════════════════════════════════════════
cls
echo.
echo  %HEADER%── Generation batch (CSV) ──%RESET%
echo.
echo   %DIM%Format CSV : discord_id,tier_code,Name-Realm%RESET%
echo   %DIM%Exemple : 123456789,REC,Plume-Hyjal%RESET%
echo.
set "csvpath="
set /p "csvpath=  Chemin du fichier CSV : "
if "%csvpath%"=="" goto menu

set "days="
set /p "days=  Jours de validite [%DEFAULT_DAYS%] : "
if "%days%"=="" set "days=%DEFAULT_DAYS%"

echo.
%PYTHON% "%KEYGEN%" --batch "%csvpath%" --days %days%
goto done

:: ═══════════════════════════════════════════════════════════════
:done
:: ═══════════════════════════════════════════════════════════════
echo.
echo  %GREEN%──────────────────────────────%RESET%
echo.
pause
goto menu
