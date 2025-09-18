@echo off
setlocal enabledelayedexpansion

if "%~2"=="" (
    echo Usage: %~n0 ModuleName file1 [file2 ...]
    exit /b 1
)

set "MODULE=%~1"

set "HEADER=%TEMP%\htest_header.ghci"
echo :set prompt "" > "%HEADER%"
echo :load %MODULE% >> "%HEADER%"

set "TESTS=%TEMP%\htest_tests.ghci"
<NUL set /p "=let tests = [" > "%TESTS%"

set "IS_FIRST=1"
for %%F in (%*) do (
	if exist %%F (
		set "FUNC=%%~nF"
		set "LINE_COUNT=0"
		set "FUNC_CALL="
		set "EXPECTED="
	
		for /f "usebackq tokens=* delims=" %%A in ("%%F") do (
			set "LINE=%%A"
	
			if "!LINE:~0,2!" == "#/" (
				REM skip comment
			) else (
				if "!LINE:~0,8!" == "#import " (
					REM process import
					>> "%HEADER%" echo !LINE:~1!
				) else (
					REM process test case
					set /a LINE_COUNT+=1
					set /a IS_EVEN_LINE=!LINE_COUNT! %% 2
					
					if !IS_EVEN_LINE! equ 1 (
						set "FUNC_CALL=!FUNC! !LINE!"
					) else (
						set "EXPECTED=!LINE!"
						
						if !IS_FIRST! equ 0 (
							<NUL set /p "=, " >> "%TESTS%"
						) else (
							set "IS_FIRST=0"
						)
						
						set "FUNC_CALL_ESCAPED=!FUNC_CALL:\=\\!"
						set "FUNC_CALL_ESCAPED=!FUNC_CALL_ESCAPED:"=\"!"
						
						<NUL set /p "=let actual = (%MODULE%.!FUNC_CALL!); expected = (!EXPECTED!) in (expected == actual, "!FUNC_CALL_ESCAPED!" ++ "\nExpected: " ++ show expected ++ "\nActual: " ++ show actual)" >> "%TESTS%"
					)
				)
			)
		)
	)
)
>> "%TESTS%" echo ]

set "SCRIPT=%TEMP%\htest.ghci"
type "%HEADER%" > "%SCRIPT%"
type "%TESTS%" >> "%SCRIPT%"
>> "%SCRIPT%" echo mapM_ ^(\ t -^> putStrLn ^(snd t ++ ^(if fst t then "\nPASS\n" else "\nFAIL\n"^)^)^) tests
>> "%SCRIPT%" echo putStrLn ^("Total: " ++ show ^(length tests^)^)
>> "%SCRIPT%" echo putStrLn ^("Failed: " ++ show ^(length ^(filter ^(\ t -^> fst t == False^) tests^)^)^)

ghci < "%SCRIPT%"

endlocal
