@echo off
setlocal

if "%~2"=="" (
    echo Usage: %~n0 ModuleName file1 [file2 ...]
    exit /b 1
)

:: === Configuration ===
set "GROUP_ID=com.github.fadingafterglow"
set "ARTIFACT_ID=htest-runner"
set "VERSION=1.0.0"
set "REPO_OWNER=fadingafterglow"
set "REPO_NAME=htest"
set "DOWNLOAD_TOKEN=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"

:: === Derive runner path ===
set "BASE_URL=https://maven.pkg.github.com/%REPO_OWNER%/%REPO_NAME%"
set "GROUP_PATH=%GROUP_ID:.=/%"
set "JAR_FILE=%ARTIFACT_ID%-%VERSION%.jar"
set "JAR_FILE_PATH=%~dp0%JAR_FILE%"
set "DOWNLOAD_URL=%BASE_URL%/%GROUP_PATH%/%ARTIFACT_ID%/%VERSION%/%JAR_FILE%"

if exist "%JAR_FILE_PATH%" (
    goto run_tests
)

:: === Remove old runner versions ===
for %%F in (%~dp0%ARTIFACT_ID%-*.jar) do (
    if exist "%%F" (
        echo Removing old runner version: %%F
        del "%%F"
    )
)

:: === Download runner ===
echo Downloading %JAR_FILE% from:
echo %DOWNLOAD_URL%
curl -s -L -H "Authorization: Bearer %DOWNLOAD_TOKEN%" -o "%JAR_FILE_PATH%" "%DOWNLOAD_URL%"

if %ERRORLEVEL% neq 0 (
    echo Failed to download runner.
    exit /b 1
)

:run_tests
setlocal enabledelayedexpansion

:: === Prepare arguments ===
set "MODULE_NAME=%~1"
set "TEST_FILES="

:: === Expand paths ===
for %%A in (%*) do (
    if %%A neq %MODULE_NAME% (
        for %%F in (%%~A) do (
            set "TEST_FILES=!TEST_FILES! "%%~fF""
        )
    )
)

:: === Invoke runner ===
java -jar %JAR_FILE_PATH% %MODULE_NAME% %TEST_FILES%

endlocal
endlocal