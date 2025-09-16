@echo off
setlocal enabledelayedexpansion

if "%~2"=="" (
    echo Usage: %~n0 ModuleName file1 [file2 ...]
    exit /b 1
)

set "MODULE=%~1"

set TEMP_SCRIPT=%TEMP%\ghci_test_script.ghci
if exist "%TEMP_SCRIPT%" del "%TEMP_SCRIPT%"

:: basic ghci setup
echo :set prompt "" >> "%TEMP_SCRIPT%"
echo :load %MODULE% >> "%TEMP_SCRIPT%"

:: collect imports into a temp file
set IMPORTS_FILE=%TEMP%\ghci_imports.tmp
if exist "%IMPORTS_FILE%" del "%IMPORTS_FILE%"

<NUL set /p "=let tests = [" > "%TEMP%\ghci_tests.tmp"
set "IS_FIRST=1"

for %%F in (%*) do (
    if exist %%F (
        set "FUNC=%%~nF"
        set "LINE_COUNT=0"
        set "FUNC_CALL="
        set "EXPECTED="

        for /f "usebackq tokens=* delims=" %%A in ("%%F") do (
            set "LINE=%%A"
            if "!LINE:~0,8!"=="#import " (
                set "IMPORT_LINE=!LINE:~8!"
                >> "%IMPORTS_FILE%" echo import !IMPORT_LINE!
            ) else (
                set /a LINE_COUNT+=1
                set /a IS_EVEN_LINE=!LINE_COUNT! %% 2
                
                if !IS_EVEN_LINE! equ 1 (
                    set "FUNC_CALL=!FUNC! %%A"
                ) else (
                    set "EXPECTED=%%A"

                    if !IS_FIRST! equ 0 (
                        <NUL set /p "=, " >> "%TEMP%\ghci_tests.tmp"
                    ) else (
                        set "IS_FIRST=0"
                    )
                    
                    <NUL set /p "=let actual = (%MODULE%.!FUNC_CALL!); expected = (!EXPECTED!) in (expected == actual, "!FUNC_CALL:"=\"!" ++ "\nExpected: " ++ show expected ++ "\nActual: " ++ show actual)" >> "%TEMP%\ghci_tests.tmp"
                )
            )
        )
    )
)

>> "%TEMP%\ghci_tests.tmp" echo ]

:: Now assemble final script: header + imports + tests
type "%TEMP_SCRIPT%" > "%TEMP%\ghci_full.tmp"
if exist "%IMPORTS_FILE%" type "%IMPORTS_FILE%" >> "%TEMP%\ghci_full.tmp"
type "%TEMP%\ghci_tests.tmp" >> "%TEMP%\ghci_full.tmp"

>> "%TEMP%\ghci_full.tmp" echo mapM_ ^(\ t -^> putStrLn ^(snd t ++ ^(if fst t then "\nPASS\n" else "\nFAIL\n"^)^)^) tests
>> "%TEMP%\ghci_full.tmp" echo putStrLn ^("Total: " ++ show ^(length tests^)^)
>> "%TEMP%\ghci_full.tmp" echo putStrLn ^("Failed: " ++ show ^(length ^(filter ^(\ t -^> fst t == False^) tests^)^)^)

ghci < "%TEMP%\ghci_full.tmp"

endlocal
