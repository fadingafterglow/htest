@echo off
setlocal enabledelayedexpansion

if "%~2"=="" (
    echo Usage: %~n0 ModuleName file1 [file2 ...]
    exit /b 1
)

set "MODULE=%~1"

set TEMP_SCRIPT=%TEMP%\ghci_test_script.ghci
if exist "%TEMP_SCRIPT%" del "%TEMP_SCRIPT%"

echo :set prompt "" >> "%TEMP_SCRIPT%"
echo :load %MODULE% >> "%TEMP_SCRIPT%"

<NUL set /p "=let tests = [" >> "%TEMP_SCRIPT%"
set "IS_FIRST=1"

for %%F in (%*) do (
	if exist %%F (
		set "FUNC=%%~nF"
		set "LINE_COUNT=0"
		set "FUNC_CALL="
		set "EXPECTED="

		for /f "usebackq tokens=* delims=" %%A in ("%%F") do (
			set /a LINE_COUNT+=1
			set /a IS_EVEN_LINE=!LINE_COUNT! %% 2
			
			if !IS_EVEN_LINE! equ 1 (
				set "FUNC_CALL=!FUNC! %%A"
			) else (
				set "EXPECTED=%%A"

				if !IS_FIRST! equ 0 (
					<NUL set /p "=, " >> "%TEMP_SCRIPT%"
				) else (
					set "IS_FIRST=0"
				)
				
				<NUL set /p "=let actual = (%MODULE%.!FUNC_CALL!); expected = (!EXPECTED!) in (expected == actual, "!FUNC_CALL:"=\"!" ++ "\nExpected: " ++ show expected ++ "\nActual: " ++ show actual)" >> "%TEMP_SCRIPT%"
			)
		)
	)
)

>> "%TEMP_SCRIPT%" echo ]
>> "%TEMP_SCRIPT%" echo mapM_ ^(\ t -^> putStrLn ^(snd t ++ ^(if fst t then "\nPASS\n" else "\nFAIL\n"^)^)^) tests
>> "%TEMP_SCRIPT%" echo putStrLn ^("Total: " ++ show ^(length tests^)^)
>> "%TEMP_SCRIPT%" echo putStrLn ^("Failed: " ++ show ^(length ^(filter ^(\ t -^> fst t == False^) tests^)^)^)

ghci < "%TEMP_SCRIPT%"

endlocal
